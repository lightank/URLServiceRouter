//
//  URLServiceRounter.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/8/1.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
//

import Foundation

public class URLServiceRouter: URLServiceRouterProtocol {
    public var rootNodeParsersBuilder: URLServiceNodeParsersBuilder?
    
    public var delegate: URLServiceRouterDelegateProtocol?
    let rootNode = URServiceNode(name: "root node", parentNode: nil)
    private var serviceBuilderMap = [String: () -> URLServiceProtocol]()
    var nodesMap = [String: URLServiceNodeProtocol]()
    let queue = DispatchQueue(label: "com.URLServiceRouter.queue", attributes: .concurrent)
    
    public static let shared = URLServiceRouter()
    
    // MARK: - node
    
    public func registerNode(from url: String, parsersBuilder: URLServiceNodeParsersBuilder? = nil) {
        if let newUrl = URL(string: url)?.nodeUrl {
            let nodeUrlKey = newUrl.nodeUrl.absoluteString
            assert(!isRegisteredNode(key: nodeUrlKey), "url: \(nodeUrlKey) already registered")
            let names = newUrl.nodeNames
            let nodeNamesKey = names.nodeUrlKey
            assert(!isRegisteredNode(key: nodeNamesKey), "url: \(nodeNamesKey) already registered")
            
            recordNodeInfo(key: nodeUrlKey, node: privateRegisterNode(from: names, parsersBuilder: parsersBuilder))
        } else {
            logInfo("register url:\(url) is invalid")
        }
    }
    
    public func isRegisteredNode(_ url: String) -> Bool {
        return isRegisteredNode(key: url.nodeUrl)
    }
    
    public func allRegisteredNodeUrls() -> [String] {
        return nodesMap.keys.sorted { $0 < $1 }
    }
    
    private func privateRegisterNode(from names: [String], parsersBuilder: URLServiceNodeParsersBuilder?) -> URLServiceNodeProtocol {
        queue.sync(flags: .barrier) { [self] in
            var currentNode: URLServiceNodeProtocol = rootNode
            names.forEach { currentNode = currentNode.registerSubNode(with: $0) }
            currentNode.parsersBuilder = parsersBuilder
            return currentNode
        }
    }
    
    private func isRegisteredNode(key: String) -> Bool {
        return nodesMap[key] != nil
    }
    
    private func recordNodeInfo(key: String, node: URLServiceNodeProtocol) {
        assert(!isRegisteredNode(key: key), "url: \(key) already registered")
        nodesMap[key] = node
    }
    
    // MARK: 服务
    
    public func registerService(name: String, builder: @escaping () -> URLServiceProtocol) {
        queue.sync(flags: .barrier) { [self] in
            assert(vaildServiceWithName(name) == nil, "service: \(name) already exist")
            serviceBuilderMap[name] = builder
        }
    }
    
    public func isRegisteredService(_ name: String) -> Bool {
        return vaildServiceWithName(name) != nil
    }
    
    public func callService(name: String, params: Any? = nil, completion: ((URLServiceProtocol?, URLServiceErrorProtocol?) -> Void)?, callback: URLServiceExecutionCallback?) {
        let resultService = vaildServiceWithName(name)
        assert(resultService != nil, "service:\(name) is not registered")
        let error: URLServiceErrorProtocol? = resultService != nil ? nil : URLServiceErrorNotFound
        completion?(resultService, error)
        
        if let service = resultService {
            var preServiceNames = service.preServiceNames
            preServiceNames.removeAll { preServiceName in
                let isRegistered = isRegisteredService(name);
                assert(isRegistered, "service:\(name) 's preServiceName:\(preServiceName) is note registered")
                return isRegistered
            }
            if (preServiceNames.isEmpty) {
                service.execute(params: params, callback: callback)
            } else {
                for (index, preServiceName) in preServiceNames.enumerated() {
                    excutPreService(currentService: service, preServiceName: preServiceName, preServiceNames: preServiceNames, index: index, decision: URLServiceDecision(next: {

                    }, complete: { (data, error) in
                    }))
                }
            }
        }
    }
    
    private func excutPreService(currentService:URLServiceProtocol,  preServiceName: String,preServiceNames:[String], index: Int, decision: URLServiceDecisionProtocol) {
        if preServiceNames.count > index {
            if let preService = vaildServiceWithName(preServiceName) {
                preService.execute(params: currentService.paramsForPreService(name: preServiceName)) { result, error in
                    currentService.preServiceCallBack(name: preServiceName, result: result, error: error, decision: URLServiceDecision(next: {
                        decision.next()
                    }, complete: { (data, error) in
                        decision.complete(data, error)
                    }))
                }
            }
        } else {
//            service.execute(params: params, callback: callback)
        }
    }
    
    public func allRegisteredServiceNames() -> [String] {
        return serviceBuilderMap.keys.sorted { $0 < $1 }
    }
    
    private func vaildServiceName(name: String?) -> String? {
        if let newName = name, isRegisteredService(newName) {
            return name
        }
        return nil
    }
    
    private func vaildServiceWithName(_ name: String?) -> URLServiceProtocol? {
        if let newName = name {
            return serviceBuilderMap[newName]?()
        }
        return nil
    }
    
    // MARK: 服务请求
    
    public func route(request: URLServiceRequestProtocol) {
        if let rootNodeParsers = rootNodeParsersBuilder?() {
            rootNodeParsers.forEach { rootNode.register(parser: $0) }
            rootNodeParsersBuilder = nil
        }
        queue.sync { [self] in
            if let newDelegate = delegate, !newDelegate.shouldRoute(request: request) {
                logInfo("URLServiceRouter request: \(request.description) is refused by \(String(describing: delegate))")
                request.updateResponse(URLServiceRequestResponse(error: URLServiceErrorForbidden))
                request.routingCompletion()
                return
            }
            
            logInfo("URLServiceRouter start router \nrequest: \(request.description)")
            rootNode.route(request: request, result: URLServiceRouteResult(completion: { [self] routerResult in
                logInfo("URLServiceRouter router completed: \(request.description) is response by \(String(describing: routerResult.responseNode)), the response chain end node is \(String(describing: routerResult.endNode)), the response service name is \(String(describing: routerResult.responseServiceName))")
                if let serviceName = routerResult.responseServiceName, isRegisteredService(serviceName) {
                    logError("URLServiceRouter router completed: \(request.description) is response by \(String(describing: routerResult.responseNode)) but the given service name: \(serviceName) is invaild")
                }
                // 先将路由结果给到请求，因为代理可能会处理这个请求结果
                request.updateResponse(URLServiceRequestResponse(serviceName: vaildServiceName(name: routerResult.responseServiceName)))
                // 路由处理请求结果
                delegate?.dynamicProcessingServiceRequest(request)
                
                // 获取最新的响应对象，注意：这个对象可能被代理处理过
                let response = request.response
                var error: URLServiceErrorProtocol?
                let responseServiceName = vaildServiceName(name: response?.serviceName)
                
                if let serviceName = responseServiceName, let _ = vaildServiceWithName(serviceName) {
                    error = nil
                } else {
                    error = URLServiceErrorNotFound
                }
                // 最后设置一下路由结果
                request.updateResponse(URLServiceRequestResponse(serviceName: responseServiceName, error: error))
                
                // 告知请求路由结束，可以进行相关回调与服务调用了
                request.routingCompletion()
                logInfo("URLServiceRouter end router \nrequest: \(request.description), \nservice:\(String(describing: responseServiceName)) \nerrorCode:\(String(describing: error?.code)) \nerrorMessage:\(String(describing: error?.message))")
            }))
        }
    }
    
    public func canHandleUrl(url: String) -> Bool {
        guard let newUrl = URL(string: url)?.nodeUrl else {
            return false
        }
        var canHandle = false
        URLServiceRequest(url: newUrl, isOnlyRouting: true).start(success: { _ in
            canHandle = true
        })
        
        return canHandle
    }
    
    // MARK: - 服务请求
    
    public func unitTestRequest(url: String, shouldDelegateProcessingRouterResult: Bool = false, completion: @escaping ((URLServiceRequestProtocol, URLServiceRouteResultProtocol) -> Void)) {
#if DEBUG
        queue.sync { [self] in
            assert(URL(string: url) != nil, "unitTest request url:\(url) is inviald")
            if let newUrl = URL(string: url) {
                let request = URLServiceRequest(url: newUrl)
                logInfo("URLServiceRouter start unitTest: \nrequest: \(request.description)")
                rootNode.route(request: request, result: URLServiceRouteResult(completion: { [self] routerResult in
                    request.updateResponse(URLServiceRequestResponse(serviceName: vaildServiceName(name: routerResult.responseServiceName)))
                    if shouldDelegateProcessingRouterResult {
                        delegate?.dynamicProcessingServiceRequest(request)
                    }
                    
                    let newRouterResult = URLServiceRouteResult(endNode: routerResult.endNode, responseNode: routerResult.responseNode, responseServiceName: vaildServiceName(name: request.response?.serviceName)) { _ in }
                    completion(request, newRouterResult)
                }))
            }
        }
#endif
    }
    
    // MARK: - 日志
    
    public func logInfo(_ message: String) {
        delegate?.logInfo(message)
    }
    
    public func logError(_ message: String) {
        delegate?.logError(message)
    }
}
