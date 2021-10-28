//
//  URLServiceRequest.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/8/2.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
//  

import Foundation

public func MainThreadExecute(_ block: @escaping () -> Void) -> Void {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}

public class URLServiceRequest: URLServiceRequestProtocol {
    public private(set) var url: URL
    public let serviceRouter: URLServiceRouterProtocol
    public private(set) var nodeNames: [String]
    private var params: [String: Any]
    public var response: URLServiceRequestResponseProtocol?
    public var success: URLServiceRequestCompletionBlock?
    public var failure: URLServiceRequestCompletionBlock?
    public var callback: URLServiceRequestCompletionBlock?
    private var serviceCallback: URLServiceExecutionCallback?
    private var isCanceled: Bool = false
    
    public init(url: URL, params: [String: Any] = [String: Any](), serviceRouter: URLServiceRouterProtocol = URLServiceRouter.shared) {
        self.url = url
        self.serviceRouter = serviceRouter
        self.nodeNames = url.nodeNames
        self.params = url.nodeQueryItems
        self.params.merge(params) {(_, new) in new}
    }
    
    public func requestParams() -> Any? {
        params[URLServiceRequestOriginalURLKey] = url.absoluteURL
        return params
    }
    
    public func updateResponse(_ response: URLServiceRequestResponseProtocol?) -> Void {
        self.response = response
    }
    
    public func routingCompletion() -> Void {
        MainThreadExecute { [self] in
            if let respons = self.response {
                if let serviceName = respons.serviceName {
                    if let newSuccess = success {
                        newSuccess(self)
                        success = nil
                    }
                    if (!isCanceled) {
                        serviceRouter.callService(name: serviceName, params: requestParams(), completion: nil, callback: serviceCallback)
                    }
                } else {
                    if let newFailure = failure {
                        newFailure(self)
                    }
                    stop()
                }
            } else {
                serviceRouter.logError("request: \(self.description)\n have no respons");
                if let newFailure = failure {
                    newFailure(self)
                }
                stop()
            }
        }
    }
    
    public func replace(nodeNames: [String], from nodeParser: URLServiceNodeParserProtocol ) -> Void {
        if nodeParser.parserType == .pre {
            self.nodeNames = nodeNames
        }
    }
    
    public func reduceOneNodeName(from node: URLServiceNodeProtocol) -> Void {
        if node.parentNode != nil {
            nodeNames.remove(at: 0)
        }
    }
    
    public func restoreOneNodeName(from node: URLServiceNodeProtocol) -> Void {
        let routedNodeNames = node.routedNodeNames()
        if (routedNodeNames.isEmpty) {
            return
        }
        self.nodeNames.insert(node.name, at: 0)
    }
    
    public func merge(params: Any, from nodeParser: URLServiceNodeParserProtocol) -> Void {
        if nodeParser.parserType == .pre && params is [String: Any] {
            self.params.merge(params as! [String : Any]) {(_, new) in new}
        }
    }
    
    public func replace(params: Any?, from nodeParser: URLServiceNodeParserProtocol) -> Void {
        if nodeParser.parserType == .pre && (params is [String: Any]?) {
            if params != nil {
                self.params = params as! [String: Any]
            } else {
                self.params.removeAll()
            }
        }
    }
    
    public func start(success: URLServiceRequestCompletionBlock? = nil, failure: URLServiceRequestCompletionBlock? = nil, callback: URLServiceRequestCompletionBlock? = nil) -> Void {
        self.success = success
        self.failure = failure
        self.callback = callback
        if callback != nil {
            serviceCallback = {[self] (result: Any?) in
                response?.data = result
                if let newCallback = self.callback {
                    MainThreadExecute {
                        newCallback(self)
                        stop()
                    }
                }
            }
        }
        serviceRouter.route(request: self)
    }
    
    public func stop() -> Void {
        success = nil
        failure = nil
        callback = nil
        serviceCallback = nil
        isCanceled = true
    }
    
    public var description: String {
        get {
            return "URLServiceRequest - url: \(String(describing: url)), params:\(String(describing: params))"
        }
    }
}
