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
    
    public static let share: URLServiceRouter = {
        return URLServiceRouter()
    }()
    
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
            var newRequest: URLServiceRequestProtocol?
            if let newDelegate = delegate {
                newRequest = newDelegate.shouldRouter(request: request)
            }
            
            if let request = newRequest {
                logInfo("URLServiceRouter start router \nrequest: \(request.description)")
                rootNode.router(request: request, result: URLServiceRouterResult(completion: { (routerResult) in
                    var error: URLServiceErrorProtocol?
                    var responseService: URLServiceProtocol?
                    if let serviceName = routerResult.responseServiceName, let service = self.servicesMap[serviceName] {
                        responseService = service
                        if let newDelegate = delegate {
                            responseService = newDelegate.dynamicProcessingRouterResult(request: request, service: service)
                        }
                    } else {
                        responseService = delegate?.dynamicProcessingRouterResult(request: request, service: nil)
                        error = URLServiceErrorNotFound
                    }
                    
                    if let newResponseService = responseService {
                        error = newResponseService.meetTheExecutionConditions()
                    }
                    
                    request.completion(response: URLServiceRequestResponse(service: responseService, error: error))
                    self.logInfo("URLServiceRouter end router \nrequest: \(request.description), \nservice:\(String(describing: responseService?.name)) \nerrorCode:\(String(describing: error?.code)) \nerrorMessage:\(String(describing: error?.message))")
                }))
            } else {
                logInfo("URLServiceRouter request: \(request.description) is refused by \(String(describing: delegate))")
            }
        }
    }
    
    public func unitTestRequest(url: String, shouldDelegateProcessingRouterResult: Bool = false, completion: @escaping ((URLServiceRequestProtocol, URLServiceRouterResultProtocol) -> Void)) -> Void {
        queue.sync { [self] in
            assert(URL(string: url) != nil, "unitTest request url:\(url) is inviald")
            if let newUrl = URL(string: url) {
                let request = URLServiceRequest(url: newUrl)
                logInfo( "URLServiceRouter start unitTest: \nrequest: \(request.description)")
                rootNode.router(request: request, result: URLServiceRouterResult(completion: {[self] (routerResult) in
                    if shouldDelegateProcessingRouterResult == true, let newDelegate = delegate {
                        var resultService: URLServiceProtocol?
                        if let serviceName = routerResult.responseServiceName, let service = servicesMap[serviceName] {
                            resultService = service
                        }
                        resultService = newDelegate.dynamicProcessingRouterResult(request: request, service: resultService)
                        let newRouterResult = URLServiceRouterResult(endNode: routerResult.endNode, responseNode: routerResult.responseNode, responseServiceName: routerResult.responseServiceName) { (result) in}
                        completion(request, newRouterResult)
                    } else {
                        completion(request, routerResult)
                    }
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
    
    private func callService(_ service: URLServiceProtocol, callback: URLServiceExecutionCallback? = nil) -> URLServiceErrorProtocol? {
        queue.sync {
            service.execute(callback: callback)
            return service.meetTheExecutionConditions()
        }
    }
    
    private func searchService(name: String, params: Any? = nil) -> URLServiceProtocol? {
        let resultService = servicesMap[name]
        resultService?.setParams(params)
        return resultService
    }
    
    public func isServiceValid(with name: String) -> Bool {
        let resultService = servicesMap[name]
        return resultService != nil
    }
    
    public func callService(name: String, params: Any? = nil, completion: ((URLServiceProtocol?, URLServiceErrorProtocol?) -> Void)?, callback: URLServiceExecutionCallback?) -> Void {
        let resultService = searchService(name: name, params: params)
        let error:URLServiceErrorProtocol? = resultService != nil ? resultService?.meetTheExecutionConditions() : URLServiceErrorNotFound
        if let newCompletion = completion {
            newCompletion(resultService, error)
        }
        if let service = resultService {
            let _ = callService(service, callback: callback)
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
