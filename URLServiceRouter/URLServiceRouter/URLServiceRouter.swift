//
//  URLServiceRounter.swift
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/8/1.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

import Foundation

class URLServiceRouter: URLServiceRouterProtocol {
    public static let share: URLServiceRouter = {
        return URLServiceRouter()
    }()
    
    let rootNode = URServiceNode(name: "root node", nodeType: .root, parentNode: nil)
    var servicesMap = [String: URLServiceProtocol]()
    var nodesMap = [String: URLServiceNodelProtocol]()
    let queue = DispatchQueue(label: "com.huanyu.URLServiceRouter.queue", attributes: .concurrent)

    func router(request: URLServiceRequestProtocol) {
        queue.sync(flags:.barrier) { [self] in
            rootNode.router(request: request, result: URLServiceRouterResult(completion: { (routerResult) in
                
            }))
        }
    }
    
    func registerNode(from url: String, completion: @escaping (URLServiceNodelProtocol) -> Void) {
        queue.sync(flags:.barrier) { [self] in
            if let newUrl = URL(string: url)?.nodeUrl {
                let nodeUrlKey = newUrl.absoluteString
                assert(nodesMap[nodeUrlKey] == nil, "url: \(url) already registed")

                var currentNode:URLServiceNodelProtocol = rootNode;
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
    
    public func allRegistedUrl() -> [String] {
        return nodesMap.keys.sorted { $0 < $1 }
    }
}
