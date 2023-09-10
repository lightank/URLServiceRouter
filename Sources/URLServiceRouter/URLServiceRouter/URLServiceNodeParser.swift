//
//  URLNodeParser.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/7/31.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
//

import Foundation

public struct URLServiceNoramlParser: URLServiceNodeParserProtocol {
    public let priority: Int
    public let parserType: URLServiceNodeParserType
    public let parseBlock: (URLServiceNodeParserProtocol, URLServiceRequestProtocol, URLServiceNodeParserDecisionProtocol) -> Void

    public func parse(request: URLServiceRequestProtocol, decision: URLServiceNodeParserDecisionProtocol) {
        parseBlock(self, request, decision)
    }

    public init(priority: Int = URLServiceNodeParserPriorityDefault, parserType: URLServiceNodeParserType, parseBlock: @escaping (URLServiceNodeParserProtocol, URLServiceRequestProtocol, URLServiceNodeParserDecisionProtocol) -> Void) {
        self.priority = priority
        self.parserType = parserType
        self.parseBlock = parseBlock
    }
}
