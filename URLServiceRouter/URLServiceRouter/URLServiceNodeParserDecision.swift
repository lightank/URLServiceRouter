//
//  URLNodeParserDecision.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/7/31.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
//

import Foundation

public struct URLServiceNodeParserDecision: URLServiceNodeParserDecisionProtocol {    
    public let next: () -> Void
    public let complete: (String) -> Void
    
    public init(next: @escaping () -> Void, complete: @escaping (String) -> Void) {
        self.next = next
        self.complete = complete
    }
}
