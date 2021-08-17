//
//  URLNodeParser.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/7/31.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
//

import Foundation

public struct URLServiceNoramlParser :URLServiceNodeParserProtocol {
    public let priority: Int
    public var parserType: URLServiceNodeParserType
    var parseBlock: (URLServiceNodeParserProtocol, URLServiceRequestProtocol, URLServiceNodeProtocol, URLServiceNodeParserDecisionProtocol) -> Void
    
    public func parse(request: URLServiceRequestProtocol, currentNode: URLServiceNodeProtocol, decision: URLServiceNodeParserDecisionProtocol) {
        parseBlock(self, request, currentNode, decision)
    }
    
    init(priority: Int = URLServiceNodeParserPriorityDefault, parserType: URLServiceNodeParserType, parseBlock: @escaping (URLServiceNodeParserProtocol, URLServiceRequestProtocol, URLServiceNodeProtocol, URLServiceNodeParserDecisionProtocol) -> Void) {
        self.priority = priority
        self.parserType = parserType
        self.parseBlock = parseBlock
    }
}

