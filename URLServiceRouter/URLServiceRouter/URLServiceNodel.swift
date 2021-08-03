//
//  URLNode.swift
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/7/30.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

import Foundation

public class URServiceNode: URLServiceNodeProtocol {
    
    public let name: String
    public let nodeType: URLServiceNodeType
    public let parentNode: URLServiceNodeProtocol?
    public private(set) var subNodes: [URLServiceNodeProtocol] = []
    public private(set) var preParsers: [URLServiceNodeParserProtocol] = []
    public private(set) var postParsers: [URLServiceNodeParserProtocol] = []
    
    init(name: String, nodeType:URLServiceNodeType, parentNode: URLServiceNodeProtocol?) {
        self.name = name;
        self.nodeType = nodeType;
        self.parentNode = parentNode;
    }
    
    func fullPath() -> String {
        var components = [name]
        var parent = parentNode
        while parent != nil && parent!.nodeType != .root {
            components.insert(parent!.name, at: 0)
            parent = parent?.parentNode
        }
        return components.joined(separator: "/")
    }
    
    public func routedNodeNames() -> [String] {
        var routedNodeNames = [String]()
        if nodeType != .root {
            var currentNode:URLServiceNodeProtocol? = self
            while currentNode != nil && currentNode!.nodeType != .root  {
                routedNodeNames.insert(currentNode!.name, at: 0)
                currentNode = currentNode?.parentNode
            }
        }
        return routedNodeNames;
    }
    
    public func registeSubNode(with name: String, type: URLServiceNodeType) -> URLServiceNodeProtocol {
        let lowercasedName = name.lowercased()
        if let subNode = subNodes.first(where: {($0.name == lowercasedName) && ($0.nodeType == type)}) {
            return subNode;
        }

        let node = URServiceNode(name: lowercasedName, nodeType: type, parentNode: self)
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
        return subNodes.contains { (node) -> Bool in
            return (subNode.name == node.name) && (subNode.nodeType == subNode.nodeType)
        }
    }
    
    public func registe(parser: URLServiceNodeParserProtocol) -> Void {
        switch parser.parserType {
        case .pre:
            let index = preParsers.binarySearch(predicate: { $0.priority >= parser.priority })
            preParsers.insert(parser, at: index)
        case .post:
            let index = postParsers.binarySearch(predicate: { $0.priority >= parser.priority })
            postParsers.insert(parser, at: index)
        }
    }
    
    public func router(request: URLServiceRequestProtocol, result: URLServiceRouterResultProtocol) {
        routerPreParser(request: request, result: result)
    }
    
    public func routerPreParser(request: URLServiceRequestProtocol, result: URLServiceRouterResultProtocol) {
        preParser(request: request, parserIndex: 0, decision: URLServiceNodeParserDecision(next: { [self] in
            if let nodeName = request.nodeNames.first, let node = self.subNodes.first(where: {$0.name == nodeName}) {
                request.reduceOneNodeName(from: node)
                node.router(request: request, result: result)
            } else {
                result.recordEndNode(self)
                routerPostParser(request: request, result: result)
            }
        }, complete: { (service) in
            result.routerCompletion(self, service)
        }))
    }
    
    func preParser(request:URLServiceRequestProtocol, parserIndex: Int, decision: URLServiceNodeParserDecisionProtocol) {
        if preParsers.count > parserIndex {
            preParsers[parserIndex].parse(request: request, currentNode: self, decision: URLServiceNodeParserDecision(next: { [self] in
                preParser(request:request, parserIndex: parserIndex + 1, decision: decision)
            }, complete: { (result) in
                decision.complete(result);
            }))
        } else {
            decision.next()
        }
    }
    
    public func routerPostParser(request: URLServiceRequestProtocol, result: URLServiceRouterResultProtocol) {
        postParser(request: request, parserIndex: 0, decision: URLServiceNodeParserDecision(next: { [self] in
            if let parentNode = parentNode {
                request.restoreOneNodeName(from: self)
                parentNode.routerPostParser(request: request, result: result)
            } else {
                result.routerCompletion(self, nil)
            }
        }, complete: { (service) in
            result.routerCompletion(self, service)
        }))
    }
    
    func postParser(request:URLServiceRequestProtocol, parserIndex: Int, decision: URLServiceNodeParserDecisionProtocol) {
        if postParsers.count > parserIndex {
            postParsers[parserIndex].parse(request: request, currentNode: self, decision: URLServiceNodeParserDecision(next: { [self] in
                postParser(request: request, parserIndex: parserIndex + 1, decision: decision)
            }, complete: { (result) in
                decision.complete(result)
            }))
        } else {
            decision.next()
        }
    }
}
