//
//  URLServiceRouteResult.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/8/2.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
//

import Foundation

public class URLServiceRouteResult: URLServiceRouteResultProtocol {    
    public private(set) var endNode: URLServiceNodeProtocol?
    public private(set) var responseNode: URLServiceNodeProtocol?
    public private(set) var responseNodeParser: URLServiceNodeParserProtocol?
    public private(set) var responseServiceName: String?
    public private(set) lazy var recordEndNode = {(node: URLServiceNodeProtocol) -> Void in
        self.endNode = node
    }
    public private(set) lazy var routerCompletion = {(node: URLServiceNodeProtocol, nodeParser: URLServiceNodeParserProtocol?, serviceName: String?) -> Void in
        self.responseNode = node
        self.responseNodeParser = nodeParser
        self.responseServiceName = serviceName
        self.completion(self)
    }
    public var completion: ((URLServiceRouteResultProtocol) -> Void)
    
    public init(endNode: URLServiceNodeProtocol? = nil, responseNode: URLServiceNodeProtocol? = nil, responseServiceName: String? = nil, completion: @escaping (URLServiceRouteResultProtocol) -> Void) {
        self.endNode = endNode
        self.responseNode = responseNode
        self.responseServiceName = responseServiceName
        self.completion = completion
    }
}
