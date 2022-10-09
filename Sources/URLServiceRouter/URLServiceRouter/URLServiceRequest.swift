//
//  URLServiceRequest.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/8/2.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
//

import Foundation

public func MainThreadExecute(_ block: @escaping () -> Void) {
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
    private let requestTimeoutInterval: TimeInterval
    private var timer: Timer?
    public let isOnlyRouting: Bool
    
    /// 初始化方法
    /// - Parameters:
    ///   - url: 请求url
    ///   - params: 额外的请求参数
    ///   - requestTimeoutInterval: 请求超时时长，默认值为0，也就是说没有超时时长，时长大于0的时候时长才会生效，到时间就自动请求失败，返回 URLServiceErrorTimeout 错误
    ///   - serviceRouter: 处理请求的服务路由器
    ///   - isOnlyRouting: 是否仅路由请求但并不执行服务，默认值为 false
    public init(url: URL, params: [String: Any] = [String: Any](), requestTimeoutInterval: TimeInterval = 0, serviceRouter: URLServiceRouterProtocol = URLServiceRouter.shared, isOnlyRouting: Bool = false) {
        self.url = url
        self.serviceRouter = serviceRouter
        self.nodeNames = url.nodeNames
        self.params = url.nodeQueryItems
        self.params.merge(params) { _, new in new }
        self.requestTimeoutInterval = requestTimeoutInterval
        self.isOnlyRouting = isOnlyRouting
    }
    
    // MARK: - route
    
    public func requestParams() -> Any? {
        params[URLServiceRequestOriginalURLKey] = url.absoluteURL
        return params
    }
    
    public func updateResponse(_ response: URLServiceRequestResponseProtocol?) {
        self.response = response
    }
    
    public func routingCompletion() {
        MainThreadExecute { [self] in
            if let serviceName = self.response?.serviceName, serviceRouter.isRegisteredService(serviceName) {
                requestSucceeded(serviceName: serviceName)
            } else {
                requestFailed()
            }
        }
    }
    
    public func replace(nodeNames: [String], from nodeParser: URLServiceNodeParserProtocol) {
        if nodeParser.parserType == .pre {
            self.nodeNames = nodeNames
        }
    }
    
    public func reduceOneNodeName(from node: URLServiceNodeProtocol) {
        if node.parentNode != nil {
            nodeNames.remove(at: 0)
        }
    }
    
    public func restoreOneNodeName(from node: URLServiceNodeProtocol) {
        if node.routedNodeNames().isEmpty {
            return
        }
        nodeNames.insert(node.name, at: 0)
    }
    
    public func merge(params: Any, from nodeParser: URLServiceNodeParserProtocol) {
        if nodeParser.parserType == .pre, params is [String: Any] {
            self.params.merge(params as! [String: Any]) { _, new in new }
        }
    }
    
    public func replace(params: Any?, from nodeParser: URLServiceNodeParserProtocol) {
        if nodeParser.parserType == .pre, params is [String: Any]? {
            if params != nil {
                self.params = params as! [String: Any]
            } else {
                self.params.removeAll()
            }
        }
    }
    
    // MARK: - request
    
    public func start(success: URLServiceRequestCompletionBlock? = nil, failure: URLServiceRequestCompletionBlock? = nil, callback: URLServiceRequestCompletionBlock? = nil) {
        let existCallback = !(success == nil && failure == nil && callback == nil)
        if requestTimeoutInterval > 0, existCallback {
            let timer = Timer(timeInterval: requestTimeoutInterval, repeats: false) { [self] _ in
                requestTimeout()
            }
            RunLoop.current.add(timer, forMode: .default)
            timer.fire()
            self.timer = timer
        }
        
        self.success = success
        self.failure = failure
        self.callback = callback
        if callback != nil {
            serviceCallback = { [self] (result: Any?, error: URLServiceErrorProtocol?) in
                response?.data = result
                response?.error = error
                MainThreadExecute { [self] in
                    callback?(self)
                    stop()
                }
            }
        }
        serviceRouter.route(request: self)
    }
    
    private func requestSucceeded(serviceName: String) {
        success?(self)
        success = nil
        
        if isOnlyRouting {
            stop()
        }
        
        if !isCanceled {
            serviceRouter.callService(name: serviceName, params: requestParams(), completion: nil, callback: serviceCallback)
        }
    }
    
    private func requestFailed() {
        failure?(self)
        failure = nil
        
        stop()
    }
    
    private func requestTimeout() {
        updateResponse(URLServiceRequestResponse(serviceName: nil, error: URLServiceErrorRequestTimeout))
        requestFailed()
    }
    
    public func stop() {
        isCanceled = true
        timer?.invalidate()
        
        success = nil
        failure = nil
        callback = nil
        serviceCallback = nil
    }
    
    public var description: String {
        "URLServiceRequest - url: \(String(describing: url)), params:\(String(describing: params))"
    }
}
