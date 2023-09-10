//
//  URLServiceDecision.swift
//  URLServiceRouter
//
//  Created by huanyu on 2023/8/21.
//

import Foundation

public struct URLServiceDecision: URLServiceDecisionProtocol {
    public var next: () -> Void
    public var complete: () -> Void

    public init(next: @escaping () -> Void, complete: @escaping () -> Void) {
        self.next = next
        self.complete = complete
    }
}
