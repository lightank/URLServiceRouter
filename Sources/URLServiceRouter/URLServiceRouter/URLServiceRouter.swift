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
    
    public func config(delegate: URLServiceRouterDelegateProtocol) -> Void {
        queue.sync { [self] in
            self.delegate = delegate
            if let parsers = delegate.rootNodeParsers() {
                parsers.forEach { rootNode.registe(parser: $0) }
            }
        }
    }
    
    public func router(request: URLServiceRequestProtocol) {
        queue.sync { [self] in
            if let newDelegate = delegate, !newDelegate.shouldRouter(request: request) {
                logInfo("URLServiceRouter request: \(request.description) is refused by \(String(describing: delegate))")
                request.routingCompletion()
                return
            }
            
            logInfo("URLServiceRouter start router \nrequest: \(request.description)")
            rootNode.router(request: request, result: URLServiceRouterResult(completion: { (routerResult) in
                request.updateResponse(URLServiceRequestResponse(serviceName: routerResult.responseServiceName))
                if let newDelegate = delegate {
                    newDelegate.dynamicProcessingRouterRequest(request)
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
                self.logInfo("URLServiceRouter end router \nrequest: \(request.description), \nservice:\(String(describing: responseService?.name)) \nerrorCode:\(String(describing: error?.code)) \nerrorMessage:\(String(describing: error?.message))")
            }))
        }
    }
    
    public func unitTestRequest(url: String, shouldDelegateProcessingRouterResult: Bool = false, completion: @escaping ((URLServiceRequestProtocol, URLServiceRouterResultProtocol) -> Void)) -> Void {
        queue.sync { [self] in
            assert(URL(string: url) != nil, "unitTest request url:\(url) is inviald")
            if let newUrl = URL(string: url) {
                let request = URLServiceRequest(url: newUrl)
                logInfo( "URLServiceRouter start unitTest: \nrequest: \(request.description)")
                rootNode.router(request: request, result: URLServiceRouterResult(completion: {[self] (routerResult) in
                    request.updateResponse(URLServiceRequestResponse(serviceName: routerResult.responseServiceName))
                    if shouldDelegateProcessingRouterResult == true, let newDelegate = delegate {
                        newDelegate.dynamicProcessingRouterRequest(request)
                    }
                    
                    let newRouterResult = URLServiceRouterResult(endNode: routerResult.endNode, responseNode: routerResult.responseNode, responseServiceName: request.response?.serviceName) { (result) in}
                    completion(request, newRouterResult)
                }))
            }
        }
    }
    
    public func registerNode(from names: [String], parsers: [URLServiceNodeParserProtocol]?) {
        if (names.isEmpty) {return}
        queue.sync(flags:.barrier) { [self] in
            let nodeUrlKey = names.joined(separator: "/")
            assert(nodesMap[nodeUrlKey] == nil, "url: \(nodeUrlKey) already registed")
            
            var currentNode:URLServiceNodeProtocol = rootNode;
            names.forEach { currentNode = currentNode.registeSubNode(with: $0) }
            nodesMap[nodeUrlKey] = currentNode
            if let newParsers = parsers {
                newParsers.forEach { currentNode.registe(parser: $0) }
            }
        }
    }
    
    public func registerNode(from url: String, parsers: [URLServiceNodeParserProtocol]? = nil) {
        if let newUrl = URL(string: url)?.nodeUrl {
            let paths = newUrl.nodeNames
            registerNode(from: paths, parsers: parsers)
        }
    }
    
    public func register(service: URLServiceProtocol) {
        queue.sync(flags:.barrier) { [self] in
            assert(servicesMap[service.name] == nil, "service: \(service.name) already exist")
            servicesMap[service.name] = service
        }
    }
    
    public func isServiceValid(with name: String) -> Bool {
        let resultService = servicesMap[name]
        return resultService != nil
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
    
    public func logInfo(_ message: String) {
        delegate?.logInfo(message)
    }
    
    public func logError(_ message: String) {
        delegate?.logError(message)
    }
    
    public func allRegistedNodeUrls() -> [String] {
        queue.sync {
            return nodesMap.keys.sorted { $0 < $1 }
        }
    }
    
    public func allRegistedServiceNames() -> [String] {
        queue.sync {
            return servicesMap.keys.sorted { $0 < $1 }
        }
    }
}
