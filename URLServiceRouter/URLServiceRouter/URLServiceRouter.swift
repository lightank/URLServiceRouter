//
//  URLServiceRounter.swift
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/8/1.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

import Foundation

class URLServiceRouter: URLServiceRouterProtocol {
    let delegate: URLServiceRouterDelegateProtocol
    let rootNode = URServiceNode(name: "root node", nodeType: .root, parentNode: nil)
    var servicesMap = [String: URLServiceProtocol]()
    var nodesMap = [String: URLServiceNodeProtocol]()
    let queue = DispatchQueue(label: "com.huanyu.URLServiceRouter.queue", attributes: .concurrent)
    
    init(delegate: URLServiceRouterDelegateProtocol) {
        self.delegate = delegate
        registerRootNodeParser()
        registerLevelOneNodes()
    }
    
    private func registerRootNodeParser() {
        queue.sync(flags:.barrier) { [self] in
            delegate.rootNodeParsers.forEach { (nodeParser) in
                rootNode.registe(parser: URLServiceRedirectHttpParser())
            }
        }
    }
    
    private func registerLevelOneNodes() {
        queue.sync(flags:.barrier) { [self] in
            delegate.levelOneNodes.forEach { (node) in
                rootNode.registe(subNode: node)
            }
        }
    }

    func router(request: URLServiceRequestProtocol) {
        queue.sync(flags:.barrier) { [self] in
            rootNode.router(request: request, result: URLServiceRouterResult(completion: { (routerResult) in
                var error: URLServiceErrorProtocol? = nil
                if let service = routerResult.responseService {
                    error = service.meetTheExecutionConditions()
                } else {
                    error = URLServiceErrorNotFound
                }
                request.completion(response: URLServiceRequestResponse(service: routerResult.responseService, error: error))
            }))
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
        queue.sync(flags: .barrier) { [self] in
            assert(servicesMap[service.name] == nil, "service: \(service.name) already exist")
            servicesMap[service.name] = service
        }
    }
    
    func callService(_ service: URLServiceProtocol) ->URLServiceErrorProtocol? {
        let _ = service.execute()
        return service.meetTheExecutionConditions()
    }
    
    func callService(name: String, params: Any?, completion: ((URLServiceProtocol?) -> Void)?) ->URLServiceErrorProtocol? {
        let resultService = servicesMap[name]
        if let service = resultService {
            service.setParams(params)
            if let newCompletion = completion {
                newCompletion(resultService)
            }
            return callService(service)
        } else {
            if let newCompletion = completion {
                newCompletion(resultService)
            }
            return URLServiceErrorNotFound
        }
    }
    
    public func allRegistedUrls() -> [String] {
        queue.sync(flags: .barrier) { [self] in
            return nodesMap.keys.sorted { $0 < $1 }
        }
    }
    
    public func allRegistedServices() -> [String] {
        queue.sync(flags: .barrier) { [self] in
            return servicesMap.keys.sorted { $0 < $1 }
        }
    }
}
