//
//  URLServiceRequestResponse.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/8/2.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
//

import Foundation

class URLServiceRequestResponse: URLServiceRequestResponseProtocol {
    public private(set) var service: URLServiceProtocol?
    public private(set) var error: URLServiceErrorProtocol?
    var data: Any?
    
    init(service: URLServiceProtocol?, error: URLServiceErrorProtocol?) {
        self.service = service
        if (error != nil) {
            self.error = error
        } else {
            if let newService = service {
                self.error = newService.meetTheExecutionConditions()
            }
        }
    }
}
