//
//  URLServiceRequestResponse.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/8/2.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
//

import Foundation

public struct URLServiceRequestResponse: URLServiceRequestResponseProtocol {
    public var serviceName: String?
    public var error: URLServiceErrorProtocol?
    public var data: Any?

    init(serviceName: String? = nil, error: URLServiceErrorProtocol? = nil) {
        self.serviceName = serviceName
        self.error = error
    }
}
