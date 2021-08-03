//
//  URLServiceRounter.swift
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/8/1.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

import Foundation

class URLServiceRouter: URLServiceRouterProtocol {
    let delegate: URLServiceRouterDelegateProtocol?
    let rootNode = URServiceNode(name: "root node", nodeType: .root, parentNode: nil)
    var servicesMap = [String: URLServiceProtocol]()
    var nodesMap = [String: URLServiceNodeProtocol]()
    let queue = DispatchQueue(label: "com.huanyu.URLServiceRouter.queue", attributes: .concurrent)
    
    init(delegate: URLServiceRouterDelegateProtocol? = nil) {
        self.delegate = delegate
        delegate?.configRootNode(rootNode)
    }

    func router(request: URLServiceRequestProtocol) {
//        queue.sync(flags:.barrier) { [self] in
            logInfo("URLServiceRouter start \nrequest: \(request.description)")
            rootNode.router(request: request, result: URLServiceRouterResult(completion: { (routerResult) in
                var error: URLServiceErrorProtocol? = nil
                if let serviceName = routerResult.responseServiceName, let service = self.servicesMap[serviceName] {
                    error = service.meetTheExecutionConditions()
                    request.completion(response: URLServiceRequestResponse(service: service, error: error))
                } else {
                    error = URLServiceErrorNotFound
                    request.completion(response: URLServiceRequestResponse(service: nil, error: error))
                }
//                self.logInfo("URLServiceRouter end \nrequest: \(request.description), \nservice:\(String(describing: routerResult.responseService?.name)) \nerrorCode:\(String(describing: error?.code)) \nerrorMessage:\(String(describing: error?.content))")
                
            }))
//        }
    }
    
    func unitTest(url: String, completion: @escaping ((URLServiceProtocol?, Any?) -> Void))  -> Void {
        if let newUrl = URL(string: url) {
            let request = URLServiceRequest(url: newUrl, serviceRouter: self)
            delegate?.logInfo(message: "URLServiceRouter start \nrequest: \(request.description)")
            rootNode.router(request: request, result: URLServiceRouterResult(completion: { (routerResult) in
                if let serviceName = routerResult.responseServiceName, let service = self.servicesMap[serviceName] {
                    completion(service, request.requestParams())
                } else {
                    completion(nil, request.requestParams())
                }
//                logInfo( "URLServiceRouter end \nunitTest request: \(request.description),\nservice:\(String(describing: routerResult.responseService?.name))")
            }))
        } else {
            completion(nil, nil)
        }
    }
    
    func registerNode(from url: String, completion: @escaping (URLServiceNodeProtocol) -> Void) {
//        queue.sync(flags:.barrier) { [self] in
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
//        }
    }
    
    func register(service: URLServiceProtocol) {
//        queue.sync(flags: .barrier) { [self] in
            assert(servicesMap[service.name] == nil, "service: \(service.name) already exist")
            servicesMap[service.name] = service
//        }
    }
    
    func callService(_ service: URLServiceProtocol, callback: URLServiceExecutionCallback? = nil) -> URLServiceErrorProtocol? {
        service.execute(callback: callback)
        return service.meetTheExecutionConditions()
    }
    
    func callService(name: String, params: Any?, completion: ((URLServiceProtocol?) -> Void)?, callback: URLServiceExecutionCallback? = nil) ->URLServiceErrorProtocol? {
        let resultService = servicesMap[name]
        if let service = resultService {
            service.setParams(params)
            if let newCompletion = completion {
                newCompletion(resultService)
            }
            return callService(service, callback: callback)
        } else {
            if let newCompletion = completion {
                newCompletion(resultService)
            }
            return URLServiceErrorNotFound
        }
    }
    
    func logInfo(_ message: String) {
        delegate?.logInfo(message: message)
    }
    
    func logError(_ message: String) {
        delegate?.logError(message: message)
    }
    
    public func allRegistedUrls() -> [String] {
        return nodesMap.keys.sorted { $0 < $1 }
    }
    
    public func allRegistedServices() -> [String] {
        return servicesMap.keys.sorted { $0 < $1 }
    }
}
