//
//  URLNode.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/7/30.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
//

import Foundation

public class URServiceNode: URLServiceNodeProtocol {
    public let name: String
    public let parentNode: URLServiceNodeProtocol?
    public private(set) var preParsers: [URLServiceNodeParserProtocol] = []
    public private(set) var postParsers: [URLServiceNodeParserProtocol] = []
    public var parsersBuilder: URLServiceNodeParsersBuilder?
    private var subNodesDict: [String: URLServiceNodeProtocol] = [:]
    
    init(name: String, parentNode: URLServiceNodeProtocol?) {
        self.name = name
        self.parentNode = parentNode
    }
    
    public func routedNodeNames() -> [String] {
        var routedNodeNames = [String]()
        if parentNode != nil {
            var currentNode: URLServiceNodeProtocol? = self
            while let current = currentNode, let parent = current.parentNode {
                routedNodeNames.append(current.name)
                currentNode = parent
            }
        }
        return routedNodeNames.reversed()
    }
    
    public func registerSubNode(with name: String) -> URLServiceNodeProtocol {
        if let subNode = subNodesDict[name] {
            return subNode
        }
        
        let node = URServiceNode(name: name, parentNode: self)
        register(subNode: node)
        return node
    }
    
    public func register(subNode: URLServiceNodeProtocol) {
        if exitedSubNode(subNode) {
            assert(true, "node: \(name) have register subNode: \(subNode.name)")
        }
        
        subNodesDict[subNode.name] = subNode
    }
    
    func exitedSubNode(_ subNode: URLServiceNodeProtocol) -> Bool {
        return subNodesDict.contains { (_: String, value: URLServiceNodeProtocol) in
            subNode.name == value.name
        }
    }
    
    public func register(parser: URLServiceNodeParserProtocol) {
        switch parser.parserType {
        case .pre:
            let index = preParsers.binarySearch(predicate: { $0.priority >= parser.priority })
            preParsers.insert(parser, at: index)
        case .post:
            let index = postParsers.binarySearch(predicate: { $0.priority >= parser.priority })
            postParsers.insert(parser, at: index)
        }
    }
    
    public func route(request: URLServiceRequestProtocol, result: URLServiceRouteResultProtocol) {
        if let parsers = parsersBuilder?() {
            parsers.forEach { register(parser: $0) }
            parsersBuilder = nil
        }
        // 路由查找
        routePreParser(request: request, result: result)
    }
    
    public func routePreParser(request: URLServiceRequestProtocol, result: URLServiceRouteResultProtocol) {
        preParser(request: request, parserIndex: 0, decision: URLServiceNodeParserDecision(next: { [self] in
            if let nodeName = request.nodeNames.first, let node = self.subNodesDict[nodeName] {
                request.reduceOneNodeName(from: node)
                node.route(request: request, result: result)
            } else {
                result.recordEndNode(self)
                // 路由回溯
                routePostParser(request: request, result: result)
            }
        }, complete: { nodeParser, service in
            result.routerCompletion(self, nodeParser, service)
        }))
    }
    
    public func preParser(request: URLServiceRequestProtocol, parserIndex: Int, decision: URLServiceNodeParserDecisionProtocol) {
        if preParsers.count > parserIndex {
            preParsers[parserIndex].parse(request: request, decision: URLServiceNodeParserDecision(next: { [self] in
                preParser(request: request, parserIndex: parserIndex + 1, decision: decision)
            }, complete: { nodeParser, result in
                decision.complete(nodeParser, result)
            }))
        } else {
            decision.next()
        }
    }
    
    public func routePostParser(request: URLServiceRequestProtocol, result: URLServiceRouteResultProtocol) {
        postParser(request: request, parserIndex: 0, decision: URLServiceNodeParserDecision(next: { [self] in
            if let parentNode = parentNode {
                request.restoreOneNodeName(from: self)
                parentNode.routePostParser(request: request, result: result)
            } else {
                result.routerCompletion(self, nil, nil)
            }
        }, complete: { nodeParser, service in
            result.routerCompletion(self, nodeParser, service)
        }))
    }
    
    func postParser(request: URLServiceRequestProtocol, parserIndex: Int, decision: URLServiceNodeParserDecisionProtocol) {
        if postParsers.count > parserIndex {
            postParsers[parserIndex].parse(request: request, decision: URLServiceNodeParserDecision(next: { [self] in
                postParser(request: request, parserIndex: parserIndex + 1, decision: decision)
            }, complete: { nodeParser, result in
                decision.complete(nodeParser, result)
            }))
        } else {
            decision.next()
        }
    }
}
