//
//  URLServiceError.swift
//  URLServiceRouterDemo
//
//  Created by huanyu.li on 2021/8/3.
//

import Foundation

let URLServiceErrorNotFoundCode = "404"
let URLServiceErrorNotFound = URLServiceError(code: URLServiceErrorNotFoundCode, content: "service not found")

class URLServiceError: URLServiceErrorProtocol {
    var code: String
    var content: String
    
    init(code: String, content: String) {
        self.code = code
        self.content = content
    }
}
