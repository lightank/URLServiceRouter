//
//  URLServiceError.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/8/3.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
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
