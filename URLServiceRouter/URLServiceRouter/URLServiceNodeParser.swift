//
//  URLNodeParser.swift
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/7/31.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

import Foundation

struct URLServiceNoramlParser :URLServiceNodeParserProtocol {
    let priority: Int
    var parserType: URLServiceNodeParserType
    var parseBlock: (URLServiceRequestProtocol, URLServiceNodelProtocol, URLServiceNodeParserDecisionProtocol) -> Void
    
    func parse(request: URLServiceRequestProtocol, currentNode: URLServiceNodelProtocol, decision: URLServiceNodeParserDecisionProtocol) {
        parseBlock(request, currentNode, decision)
    }
    
    init(priority: Int = URLServiceNodeParserPriorityDefault, parserType: URLServiceNodeParserType, parseBlock: @escaping (URLServiceRequestProtocol, URLServiceNodelProtocol, URLServiceNodeParserDecisionProtocol) -> Void) {
        self.priority = priority
        self.parserType = parserType
        self.parseBlock = parseBlock
    }
}

struct URLServiceRedirectTestHostParser :URLServiceNodeParserProtocol {
    let priority: Int = URLServiceNodeParserPriorityDefault
    var parserType: URLServiceNodeParserType = .pre
    
    func parse(request: URLServiceRequestProtocol, currentNode: URLServiceNodelProtocol, decision: URLServiceNodeParserDecisionProtocol) {
        if let host = request.url.host, request.nodeNames.contains(host), host.isTestHost {
            var nodeNames = request.nodeNames
            nodeNames.remove(at: 0)
            nodeNames.insert("www.baidu.com", at: 0)
            request.replace(nodeNames: nodeNames, from: self)
        }
        decision.next();
    }
}

struct URLServiceRedirectHttpParser :URLServiceNodeParserProtocol {
    let priority: Int = URLServiceNodeParserPriorityDefault
    var parserType: URLServiceNodeParserType = .pre
    
    func parse(request: URLServiceRequestProtocol, currentNode: URLServiceNodelProtocol, decision: URLServiceNodeParserDecisionProtocol) {
        if let scheme = request.url.scheme, scheme == "http", request.nodeNames.contains(scheme) {
            var nodeNames = request.nodeNames
            nodeNames.remove(at: 0)
            nodeNames.insert("https", at: 0)
            request.replace(nodeNames: nodeNames, from: self)
        }
        decision.next();
    }
}
