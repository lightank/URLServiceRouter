//
//  URLServiceError.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/8/3.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
//

import Foundation

public let URLServiceErrorForbiddenCode = "403"
public let URLServiceErrorForbidden = URLServiceError(code: URLServiceErrorForbiddenCode, message: "url service router refused this request")
public let URLServiceErrorNotFoundCode = "404"
public let URLServiceErrorNotFound = URLServiceError(code: URLServiceErrorNotFoundCode, message: "service not found")
public let URLServiceErrorRequestTimeoutCode = "408"
public let URLServiceErrorRequestTimeout = URLServiceError(code: URLServiceErrorRequestTimeoutCode, message: "service request time out")

public struct URLServiceError: URLServiceErrorProtocol {
    public var code: String
    public var message: String

    public init(code: String, message: String = "") {
        self.code = code
        self.message = message
    }
}
