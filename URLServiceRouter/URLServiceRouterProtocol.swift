//
//  URLRouterProtocol.swift
//  LTURLRouterDemo
//
//  Created by huanyu.li on 2021/1/28.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

import Foundation

public protocol URLServiceRouterResultProtocol {
    var endNode: URLServiceNodelProtocol? { get }
    var responseNode: URLServiceNodelProtocol? { get }
    var responseService: URLServiceProtocol? { get }
    
    var recordEndNode: ((URLServiceNodelProtocol) -> Void) { get }
    var routerCompletion: ((URLServiceNodelProtocol, URLServiceProtocol?) -> Void) { get }
    var completion: ((URLServiceRouterResultProtocol) -> Void) { get }
}

public protocol URLServiceRouterProtocol {
    func router(request: URLServiceRequestProtocol) -> Void
    func registerNode(from url: String, completion: @escaping (URLServiceNodelProtocol) -> Void)
    func register(service: URLServiceProtocol) -> Void
}

public typealias URLServiceRequestCompletionBlock = (URLServiceRequestProtocol) -> Void
public protocol URLServiceRequestProtocol {
    var url: URL { get }
    var nodeNames: [String] { get}
    var response: URLServiceRequestResponseProtocol? { get }
    var success: URLServiceRequestCompletionBlock? { get }
    var failure: URLServiceRequestCompletionBlock? { get }
    
    func requestParams() -> Any?
    func replace(nodeNames: [String], from nodeParser: URLServiceNodeParserProtocol ) -> Void
    func reduceOneNodeName(from node: URLServiceNodelProtocol) -> Void
    func restoreOneNodeName(from node: URLServiceNodelProtocol) -> Void
    func merge(params: Any, from nodeParser: URLServiceNodeParserProtocol) -> Void
    func replace(params: Any?, from nodeParser: URLServiceNodeParserProtocol) -> Void
}

public protocol URLServiceRequestResponseProtocol {
    var service: URLServiceProtocol? { get }
    var error: URLServiceErrorProtocol? { get }
}

public enum URLServiceNodeParserType: String {
    case pre = "pre"
    case post = "post"
}

public let URLServiceNodeParserPriorityDefault = 100

public protocol URLServiceNodeParserProtocol {
    var priority: Int { get }
    var parserType: URLServiceNodeParserType { get }
    func parse(request: URLServiceRequestProtocol, currentNode: URLServiceNodelProtocol, decision: URLServiceNodeParserDecisionProtocol) -> Void
}

public protocol URLServiceNodeParserDecisionProtocol {
    var next: (() -> Void) { get }
    var complete: ((URLServiceProtocol?) -> Void) { get }
}

public enum URLServiceNodeType: String {
    case root = "root"
    case scheme = "scheme"
    case host = "host"
    case path = "path"
}

public protocol URLServiceNodelProtocol {
    var name: String { get }
    var nodeType: URLServiceNodeType { get }
    
    var parentNode: URLServiceNodelProtocol? { get }
    var subNodes: [URLServiceNodelProtocol] { get }
    func registe(subNode: URLServiceNodelProtocol) -> Void
    func registeSubNode(with name: String, type: URLServiceNodeType) -> URLServiceNodelProtocol
    
    var preParsers: [URLServiceNodeParserProtocol] { get }
    var postParsers: [URLServiceNodeParserProtocol] { get }
    func registe(parser: URLServiceNodeParserProtocol) -> Void
    
    func router(request: URLServiceRequestProtocol, result: URLServiceRouterResultProtocol) -> Void
    func routerPreParser(request: URLServiceRequestProtocol, result: URLServiceRouterResultProtocol) -> Void
    func routerPostParser(request: URLServiceRequestProtocol, result: URLServiceRouterResultProtocol) -> Void
    func routedNodeNames() -> [String]
}

public protocol URLServiceProtocol {
    var name: String { get }
    var params: Any? { get }
    func meetTheExecutionConditions() -> URLServiceErrorProtocol?
    func execute() -> ((_ object: Any?) -> Void)?
}

public protocol URLServiceErrorProtocol {
    var code: String { get }
    var content: String { get }
}
