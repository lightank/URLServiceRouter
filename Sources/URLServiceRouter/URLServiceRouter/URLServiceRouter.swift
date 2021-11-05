//
//  URLServiceRounter.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/8/1.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
//

import Foundation

public class URLServiceRouter: URLServiceRouterProtocol {
    public private(set) var delegate: URLServiceRouterDelegateProtocol?
    let rootNode = URServiceNode(name: "root node", parentNode: nil)
    var servicesMap = [String: URLServiceProtocol]()
    var nodesMap = [String: URLServiceNodeProtocol]()
    let queue = DispatchQueue(label: "com.URLServiceRouter.queue", attributes: .concurrent)
    
    public static let shared = URLServiceRouter()
    
    // MARK: - 代理
    
    public func config(delegate: URLServiceRouterDelegateProtocol) -> Void {
        queue.sync { [self] in
            self.delegate = delegate
            if let parsers = delegate.rootNodeParsers() {
                parsers.forEach { rootNode.register(parser: $0) }
            }
        }
    }
    
    // MARK: - node
    
    public func registerNode(from url: String, parsers: [URLServiceNodeParserProtocol]? = nil) {
        if let newUrl = URL(string: url)?.nodeUrl {
            let nodeUrlKey = newUrl.nodeUrl.absoluteString
            assert(!isRegisteredNode(key: nodeUrlKey), "url: \(nodeUrlKey) already registered")
            let names = newUrl.nodeNames;
            let nodeNamesKey = names.nodeUrlKey
            assert(!isRegisteredNode(key: nodeNamesKey), "url: \(nodeNamesKey) already registered")
            
            recordNodeInfo(key: nodeUrlKey, node: privateRegisterNode(from: names, parsers: parsers))
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
    
    private func privateRegisterNode(from names: [String], parsers: [URLServiceNodeParserProtocol]? = nil) -> URLServiceNodeProtocol {
        queue.sync(flags:.barrier) { [self] in
            var currentNode:URLServiceNodeProtocol = rootNode;
            names.forEach { currentNode = currentNode.registeSubNode(with: $0) }
            if let newParsers = parsers {
                newParsers.forEach { currentNode.register(parser: $0) }
            }
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
    
    public func register(service: URLServiceProtocol) {
        queue.sync(flags:.barrier) { [self] in
            assert(servicesMap[service.name] == nil, "service: \(service.name) already exist")
            servicesMap[service.name] = service
        }
    }
    
    public func isRegisteredService(_ name: String) -> Bool {
        return servicesMap[name] != nil
    }
    
    public func callService(name: String, params: Any? = nil, completion: ((URLServiceProtocol?, URLServiceErrorProtocol?) -> Void)?, callback: URLServiceExecutionCallback?) -> Void {
        let resultService = servicesMap[name]
        let error: URLServiceErrorProtocol? = resultService != nil ? resultService?.meetTheExecutionConditions(params: params) : URLServiceErrorNotFound
        if let newCompletion = completion {
            newCompletion(resultService, error)
        }
        if let service = resultService {
            service.execute(params: params, callback: callback)
        }
    }
    
    public func allRegisteredServiceNames() -> [String] {
        return servicesMap.keys.sorted { $0 < $1 }
    }
    
    // MARK: 服务请求
    
    public func route(request: URLServiceRequestProtocol) {
        queue.sync { [self] in
            if let newDelegate = delegate, !newDelegate.shouldRoute(request: request) {
                logInfo("URLServiceRouter request: \(request.description) is refused by \(String(describing: delegate))")
                request.routingCompletion()
                return
            }
            
            logInfo("URLServiceRouter start router \nrequest: \(request.description)")
            rootNode.route(request: request, result: URLServiceRouteResult(completion: { (routerResult) in
                request.updateResponse(URLServiceRequestResponse(serviceName: routerResult.responseServiceName))
                if let newDelegate = delegate {
                    newDelegate.dynamicProcessingServiceRequest(request)
                }
                
                let response = request.response;
                var error: URLServiceErrorProtocol?
                var responseService: URLServiceProtocol?
                
                if let serviceName = response?.serviceName, let service = self.servicesMap[serviceName] {
                    responseService = service
                } else {
                    error = URLServiceErrorNotFound
                }
                
                if let newResponseService = responseService {
                    error = newResponseService.meetTheExecutionConditions(params: request.requestParams())
                }
                
                request.updateResponse(URLServiceRequestResponse(serviceName: response?.serviceName, error: error))
                
                request.routingCompletion()
                logInfo("URLServiceRouter end router \nrequest: \(request.description), \nservice:\(String(describing: responseService?.name)) \nerrorCode:\(String(describing: error?.code)) \nerrorMessage:\(String(describing: error?.message))")
            }))
        }
    }
    
    // MARK: - 服务请求
    
    public func unitTestRequest(url: String, shouldDelegateProcessingRouterResult: Bool = false, completion: @escaping ((URLServiceRequestProtocol, URLServiceRouteResultProtocol) -> Void)) -> Void {
#if DEBUG
        queue.sync { [self] in
            assert(URL(string: url) != nil, "unitTest request url:\(url) is inviald")
            if let newUrl = URL(string: url) {
                let request = URLServiceRequest(url: newUrl)
                logInfo( "URLServiceRouter start unitTest: \nrequest: \(request.description)")
                rootNode.route(request: request, result: URLServiceRouteResult(completion: {[self] (routerResult) in
                    request.updateResponse(URLServiceRequestResponse(serviceName: routerResult.responseServiceName))
                    if shouldDelegateProcessingRouterResult == true, let newDelegate = delegate {
                        newDelegate.dynamicProcessingServiceRequest(request)
                    }
                    
                    let newRouterResult = URLServiceRouteResult(endNode: routerResult.endNode, responseNode: routerResult.responseNode, responseServiceName: request.response?.serviceName) { (result) in}
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
