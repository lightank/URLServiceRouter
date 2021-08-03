//
//  URLServiceRequest.swift
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/8/2.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

import Foundation

class URLServiceRequest: URLServiceRequestProtocol {
    public private(set) var url: URL
    let serviceRouter: URLServiceRouterProtocol
    public private(set) var nodeNames: [String]
    private var params: [String: Any]
    private var finalNodeNames: [String] = []
    var response: URLServiceRequestResponseProtocol?
    var success: URLServiceRequestCompletionBlock?
    var failure: URLServiceRequestCompletionBlock?
    var serviceCallback: URLServiceExecutionCallback?
    
    init(url: URL, serviceRouter: URLServiceRouterProtocol) {
        self.url = url
        self.serviceRouter = serviceRouter
        self.nodeNames = url.nodeNames
        self.params = url.nodeQueryItems
    }
    
    func requestParams() -> Any? {
        return params
    }
    
    func completion(response: URLServiceRequestResponseProtocol) {
        self.response = response
        if let service = response.service {
            if let newSuccess = success {
                newSuccess(self)
                success = nil
            }
            
            let _ = serviceRouter.callService(name: service.name, params: params, completion: nil, callback: serviceCallback)
        } else {
            if let newFailure = failure {
                newFailure(self)
                failure = nil
            }
        }
    }
    
    func replace(nodeNames: [String], from nodeParser: URLServiceNodeParserProtocol ) -> Void {
        if nodeParser.parserType == .pre {
            self.nodeNames = nodeNames
        }
    }
    
    func reduceOneNodeName(from node: URLServiceNodeProtocol) -> Void {
        if node.nodeType != .root {
            nodeNames.remove(at: 0)
        }
    }
    
    func restoreOneNodeName(from node: URLServiceNodeProtocol) -> Void {
        let routedNodeNames = node.routedNodeNames()
        if (routedNodeNames.isEmpty) {
            return
        }
        updateFinalNodeNames(with: node)
        var nodeNames = finalNodeNames
        nodeNames.removeSubrange(0..<routedNodeNames.count - 1)
        self.nodeNames = nodeNames
    }
    
    private func updateFinalNodeNames(with node: URLServiceNodeProtocol) -> Void {
        if (finalNodeNames.isEmpty) {
            let routedNodeNames = node.routedNodeNames()
            finalNodeNames = routedNodeNames + nodeNames
        }
    }
    
    func merge(params: Any, from nodeParser: URLServiceNodeParserProtocol) -> Void {
        if nodeParser.parserType == .pre && params is [String: Any] {
            self.params.merge(params as! [String : Any]) {(current, _) in current}
        }
    }
    
    func replace(params: Any?, from nodeParser: URLServiceNodeParserProtocol) -> Void {
        if nodeParser.parserType == .pre && (params is [String: Any]?) {
            if params != nil {
                self.params = params as! [String: Any]
            } else {
                self.params.removeAll()
            }
        }
    }
    
    func start() -> Void {
        serviceRouter.router(request: self)
    }
    
    func stop() -> Void {
        success = nil
        failure = nil
    }
    
    func startWithCompletionBlock(success: URLServiceRequestCompletionBlock? = nil, failure: URLServiceRequestCompletionBlock? = nil, serviceCallback:URLServiceExecutionCallback? = nil) -> Void {
        self.success = success
        self.failure = success
        self.serviceCallback = serviceCallback
        start()
    }
    
    public var description: String {
        get {
            return "URLServiceRequest - url: \(String(describing: url)), params:\(String(describing: params))"
        }
    }
}
