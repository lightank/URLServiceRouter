//
//  URLServiceRequest.swift
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/8/2.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

import Foundation

class URLServiceRequest: URLServiceRequestProtocol {
    public private(set) var url: URL
    public private(set) var nodeNames: [String]
    private var params: [String: Any]
    private var finalNodeNames: [String] = []
    var response: URLServiceRequestResponseProtocol?
    var success: URLServiceRequestCompletionBlock?
    var failure: URLServiceRequestCompletionBlock?
    
    func requestParams() -> Any? {
        return params
    }
    
    func replace(nodeNames: [String], from nodeParser: URLServiceNodeParserProtocol ) -> Void {
        if nodeParser.parserType == .pre {
            self.nodeNames = nodeNames
        }
    }
    
    func reduceOneNodeName(from node: URLServiceNodelProtocol) -> Void {
        let routedNodeNames = node.routedNodeNames()
        var nodeNames = url.nodeNames
        nodeNames.removeSubrange(0..<routedNodeNames.count)
        self.nodeNames = nodeNames
    }
    
    func restoreOneNodeName(from node: URLServiceNodelProtocol) -> Void {
        let routedNodeNames = node.routedNodeNames()
        if (routedNodeNames.isEmpty) {
            return
        }
        updateFinalNodeNames(with: node)
        var nodeNames = finalNodeNames
        nodeNames.removeSubrange(0..<routedNodeNames.count - 1)
        self.nodeNames = nodeNames
    }
    
    private func updateFinalNodeNames(with node: URLServiceNodelProtocol) -> Void {
        if (finalNodeNames.isEmpty) {
            let routedNodeNames = node.routedNodeNames()
            finalNodeNames = routedNodeNames + nodeNames
        }
    }
    
    func merge(params: Any, from nodeParser: URLServiceNodeParserProtocol) -> Void {
        if nodeParser.parserType == .pre && params is [String: Any] {
            self.params.merge(params as! [String : Any]) {(current, _) in current}
        }
    }
    
    func replace(params: Any?, from nodeParser: URLServiceNodeParserProtocol) -> Void {
        if nodeParser.parserType == .pre && (params is [String: Any]?) {
            if params != nil {
                self.params = params as! [String: Any]
            } else {
                self.params.removeAll()
            }
        }
    }
    
    init(url: URL) {
        self.url = url
        self.nodeNames = url.nodeNames
        self.params = url.nodeQueryItems
    }
}
