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
    public private(set) var subNodes: [URLServiceNodeProtocol] = []
    public private(set) var preParsers: [URLServiceNodeParserProtocol] = []
    public private(set) var postParsers: [URLServiceNodeParserProtocol] = []
    
    init(name: String, parentNode: URLServiceNodeProtocol?) {
        self.name = name;
        self.parentNode = parentNode;
    }
    
    func fullPath() -> String {
        var components = [name]
        var parent = parentNode
        while parent != nil && parent?.parentNode != nil {
            components.insert(parent!.name, at: 0)
            parent = parent?.parentNode
        }
        return components.nodeUrlKey
    }
    
    public func routedNodeNames() -> [String] {
        var routedNodeNames = [String]()
        if parentNode != nil {
            var currentNode:URLServiceNodeProtocol? = self
            while currentNode != nil && currentNode?.parentNode != nil  {
                routedNodeNames.insert(currentNode!.name, at: 0)
                currentNode = currentNode?.parentNode
            }
        }
        return routedNodeNames;
    }
    
    public func registeSubNode(with name: String) -> URLServiceNodeProtocol {
        if let subNode = subNodes.first(where: {($0.name == name)}) {
            return subNode;
        }
        
        let node = URServiceNode(name: name, parentNode: self)
        registe(subNode: node)
        return node
    }
    
    public func registe(subNode: URLServiceNodeProtocol) -> Void {
        if exitedSubNode(subNode) {
            assert(true, "node: \(name) have register subNode: \(subNode.name)")
        }
        
        let index = subNodes.binarySearch { (node) -> Bool in
            node.name.caseInsensitiveCompare(subNode.name).rawValue <= 0
        }
        subNodes.insert(subNode, at: index)
    }
    
    func exitedSubNode(_ subNode: URLServiceNodeProtocol) -> Bool {
        return subNodes.contains { subNode.name == $0.name }
    }
    
    public func register(parser: URLServiceNodeParserProtocol) -> Void {
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
        routePreParser(request: request, result: result)
    }
    
    public func routePreParser(request: URLServiceRequestProtocol, result: URLServiceRouteResultProtocol) {
        preParser(request: request, parserIndex: 0, decision: URLServiceNodeParserDecision(next: { [self] in
            if let nodeName = request.nodeNames.first, let node = self.subNodes.first(where: {$0.name == nodeName}) {
                request.reduceOneNodeName(from: node)
                node.route(request: request, result: result)
            } else {
                result.recordEndNode(self)
                routePostParser(request: request, result: result)
            }
        }, complete: { (nodeParser ,service) in
            result.routerCompletion(self, nodeParser, service)
        }))
    }
    
    func preParser(request:URLServiceRequestProtocol, parserIndex: Int, decision: URLServiceNodeParserDecisionProtocol) {
        if preParsers.count > parserIndex {
            preParsers[parserIndex].parse(request: request, decision: URLServiceNodeParserDecision(next: { [self] in
                preParser(request:request, parserIndex: parserIndex + 1, decision: decision)
            }, complete: { (nodeParser ,result) in
                decision.complete(nodeParser, result);
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
        }, complete: { (nodeParser ,service) in
            result.routerCompletion(self, nodeParser , service)
        }))
    }
    
    func postParser(request:URLServiceRequestProtocol, parserIndex: Int, decision: URLServiceNodeParserDecisionProtocol) {
        if postParsers.count > parserIndex {
            postParsers[parserIndex].parse(request: request, decision: URLServiceNodeParserDecision(next: { [self] in
                postParser(request: request, parserIndex: parserIndex + 1, decision: decision)
            }, complete: { (nodeParser ,result) in
                decision.complete(nodeParser ,result)
            }))
        } else {
            decision.next()
        }
    }
}
