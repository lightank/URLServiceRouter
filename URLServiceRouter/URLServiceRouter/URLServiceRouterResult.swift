//
//  URLServiceRouterResult.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/8/2.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
//

import Foundation

class URLServiceRouterResult: URLServiceRouterResultProtocol {
    public private(set) var endNode: URLServiceNodeProtocol?
    public private(set) var responseNode: URLServiceNodeProtocol?
    public private(set) var responseServiceName: String?
    public private(set) lazy var recordEndNode = {(node: URLServiceNodeProtocol) -> Void in
        self.endNode = node
    }
    public private(set) lazy var routerCompletion = {(node: URLServiceNodeProtocol, serviceName: String?) -> Void in
        self.responseNode = node
        self.responseServiceName = serviceName
        self.completion(self)
    }
    var completion: ((URLServiceRouterResultProtocol) -> Void)

    init(endNode: URLServiceNodeProtocol? = nil, responseNode: URLServiceNodeProtocol? = nil, responseServiceName: String? = nil, completion: @escaping (URLServiceRouterResultProtocol) -> Void) {
        self.endNode = endNode
        self.responseNode = responseNode
        self.responseServiceName = responseServiceName
        self.completion = completion
    }
}
