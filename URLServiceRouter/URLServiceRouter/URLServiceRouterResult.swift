//
//  URLServiceRouterResult.swift
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/8/2.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

import Foundation

class URLServiceRouterResult: URLServiceRouterResultProtocol {
    public private(set) var endNode: URLServiceNodelProtocol?
    public private(set) var responseNode: URLServiceNodelProtocol?
    public private(set) var responseService: URLServiceProtocol?
    public private(set) lazy var recordEndNode = {(node: URLServiceNodelProtocol) -> Void in
        self.endNode = node
    }
    public private(set) lazy var routerCompletion = {(node: URLServiceNodelProtocol, service: URLServiceProtocol?) -> Void in
        self.responseNode = node
        self.responseService = service
        self.completion(self)
    }
    var completion: ((URLServiceRouterResultProtocol) -> Void)

    init(completion: @escaping (URLServiceRouterResultProtocol) -> Void) {
        self.completion = completion
    }
}
