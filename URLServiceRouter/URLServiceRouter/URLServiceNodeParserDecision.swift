//
//  URLNodeParserDecision.swift
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/7/31.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

import Foundation

public class URLServiceNodeParserDecision: URLServiceNodeParserDecisionProtocol {
    public let next: () -> Void
    public let complete: (URLServiceProtocol?) -> Void
    
    init(next: @escaping () -> Void, complete: @escaping (URLServiceProtocol?) -> Void) {
        self.next = next
        self.complete = complete
    }
}
