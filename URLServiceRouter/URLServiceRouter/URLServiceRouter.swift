//
//  URLServiceRounter.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/8/1.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
//

import Foundation

class URLServiceRouter: URLServiceRouterProtocol {
    public private(set) var delegate: URLServiceRouterDelegateProtocol?
    let rootNode = URServiceNode(name: "root node", nodeType: .root, parentNode: nil)
    var servicesMap = [String: URLServiceProtocol]()
    var nodesMap = [String: URLServiceNodeProtocol]()
    let queue = DispatchQueue(label: "com.huanyu.URLServiceRouter.queue", attributes: .concurrent)
    
    public static let share: URLServiceRouter = {
        return URLServiceRouter()
    }()
    
    func config(delegate: URLServiceRouterDelegateProtocol) -> Void {
        self.delegate = delegate
        delegate.configRootNode(rootNode)
    }
    
    func router(request: URLServiceRequestProtocol) {
        queue.sync(flags:.barrier) { [self] in
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
                    self.logInfo("URLServiceRouter end router \nrequest: \(request.description), \nservice:\(String(describing: responseService?.name)) \nerrorCode:\(String(describing: error?.code)) \nerrorMessage:\(String(describing: error?.content))")
                }))
            } else {
                logInfo("URLServiceRouter request: \(request.description) is refused by \(String(describing: delegate))")
            }
        }
    }
    
    func unitTest(url: String, completion: @escaping ((URLServiceProtocol?, Any?) -> Void))  -> Void {
        if let newUrl = URL(string: url) {
            let request = URLServiceRequest(url: newUrl)
            logInfo( "URLServiceRouter start unitTest: \request: \(request.description)")
            rootNode.router(request: request, result: URLServiceRouterResult(completion: { (routerResult) in
                if let serviceName = routerResult.responseServiceName, let service = self.servicesMap[serviceName] {
                    completion(service, request.requestParams())
                    
                    self.logInfo( "URLServiceRouter end unitTest: \nrequest: \(request.description), \nservice: \(serviceName)")
                } else {
                    completion(nil, request.requestParams())
                    
                    self.logInfo( "URLServiceRouter end unitTest: \nrequest: \(request.description), \n not found service:")
                }
            }))
        } else {
            completion(nil, nil)
        }
    }
    
    func registerNode(from url: String, completion: @escaping (URLServiceNodeProtocol) -> Void) {
        queue.sync(flags:.barrier) { [self] in
            if let newUrl = URL(string: url)?.nodeUrl {
                let nodeUrlKey = newUrl.absoluteString
                assert(nodesMap[nodeUrlKey] == nil, "url: \(url) already registed")
                
                var currentNode:URLServiceNodeProtocol = rootNode;
                if let scheme = newUrl.scheme {
                    currentNode = currentNode.registeSubNode(with: scheme, type: .scheme)
                }
                if let host = newUrl.host {
                    currentNode = currentNode.registeSubNode(with: host, type: .host)
                }
                
                var paths = newUrl.pathComponents
                if paths.count > 0 && paths.first == "/" {
                    paths.remove(at: 0)
                }
                if !paths.isEmpty {
                    paths.forEach { (name) in
                        currentNode = currentNode.registeSubNode(with: name, type: .path)
                    }
                }
                nodesMap[nodeUrlKey] = currentNode
                completion(currentNode)
            }
        }
    }
    
    func register(service: URLServiceProtocol) {
        queue.sync(flags:.barrier) { [self] in
            assert(servicesMap[service.name] == nil, "service: \(service.name) already exist")
            servicesMap[service.name] = service
        }
    }
    
    private func callService(_ service: URLServiceProtocol, callback: URLServiceExecutionCallback? = nil) -> URLServiceErrorProtocol? {
        service.execute(callback: callback)
        return service.meetTheExecutionConditions()
    }
    
    private func searchService(name: String, params: Any? = nil) -> URLServiceProtocol? {
        let resultService = servicesMap[name]
        resultService?.setParams(params)
        return resultService
    }
    
    func isServiceValid(with name: String) -> Bool {
        let resultService = servicesMap[name]
        return resultService != nil
    }
    
    func callService(name: String, params: Any? = nil, completion: ((URLServiceProtocol?, URLServiceErrorProtocol?) -> Void)?, callback: URLServiceExecutionCallback?) -> Void {
        let resultService = searchService(name: name, params: params)
        let error:URLServiceErrorProtocol? = resultService != nil ? resultService?.meetTheExecutionConditions() : URLServiceErrorNotFound
        if let newCompletion = completion {
            newCompletion(resultService, error)
        }
        if let service = resultService {
            let _ = callService(service, callback: callback)
        }
    }
    
    func logInfo(_ message: String) {
        delegate?.logInfo(message)
    }
    
    func logError(_ message: String) {
        delegate?.logError(message)
    }
    
    public func allRegistedUrls() -> [String] {
        return nodesMap.keys.sorted { $0 < $1 }
    }
    
    public func allRegistedServices() -> [String] {
        return servicesMap.keys.sorted { $0 < $1 }
    }
}
