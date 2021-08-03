//
//  URLRouterProtocol.swift
//  LTURLRouterDemo
//
//  Created by huanyu.li on 2021/1/28.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

import Foundation
import UIKit

public protocol URLServiceRouterDelegateProtocol {
    func currentNavigationController() -> UINavigationController?
    var rootNodeParsers: [URLServiceNodeParserProtocol] { get }
    var levelOneNodes: [URLServiceNodeProtocol] { get }
    
    func isNodeVaild(name: String, type: URLServiceNodeParserType) -> Bool
    func logError(message: String) -> Void
    func logInfo(message: String) -> Void
}

public protocol URLServiceRouterProtocol {
    func router(request: URLServiceRequestProtocol) -> Void
    func registerNode(from url: String, completion: @escaping (URLServiceNodeProtocol) -> Void)
    func register(service: URLServiceProtocol) -> Void
    func callService(_ service: URLServiceProtocol) ->URLServiceErrorProtocol?
    func callService(name: String, params: Any?, completion: ((URLServiceProtocol?) -> Void)?) ->URLServiceErrorProtocol?
    
    func allRegistedUrls() -> [String]
    func allRegistedServices() -> [String]
}

public protocol URLServiceRouterResultProtocol {
    var endNode: URLServiceNodeProtocol? { get }
    var responseNode: URLServiceNodeProtocol? { get }
    var responseService: URLServiceProtocol? { get }
    
    var recordEndNode: ((URLServiceNodeProtocol) -> Void) { get }
    var routerCompletion: ((URLServiceNodeProtocol, URLServiceProtocol?) -> Void) { get }
    var completion: ((URLServiceRouterResultProtocol) -> Void) { get }
}

public typealias URLServiceRequestCompletionBlock = (URLServiceRequestProtocol) -> Void
public protocol URLServiceRequestProtocol {
    var url: URL { get }
    var serviceRouter: URLServiceRouterProtocol { get }
    var nodeNames: [String] { get }
    var response: URLServiceRequestResponseProtocol? { get }
    var success: URLServiceRequestCompletionBlock? { get }
    var failure: URLServiceRequestCompletionBlock? { get }
    
    func completion(response: URLServiceRequestResponseProtocol) -> Void
    func requestParams() -> Any?
    func replace(nodeNames: [String], from nodeParser: URLServiceNodeParserProtocol ) -> Void
    func reduceOneNodeName(from node: URLServiceNodeProtocol) -> Void
    func restoreOneNodeName(from node: URLServiceNodeProtocol) -> Void
    func merge(params: Any, from nodeParser: URLServiceNodeParserProtocol) -> Void
    func replace(params: Any?, from nodeParser: URLServiceNodeParserProtocol) -> Void
    
    func start() -> Void
    func stop() -> Void
    func startWithCompletionBlock(success: URLServiceRequestCompletionBlock?, failure: URLServiceRequestCompletionBlock?) -> Void
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
    func parse(request: URLServiceRequestProtocol, currentNode: URLServiceNodeProtocol, decision: URLServiceNodeParserDecisionProtocol) -> Void
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

public protocol URLServiceNodeProtocol {
    var name: String { get }
    var nodeType: URLServiceNodeType { get }
    
    var parentNode: URLServiceNodeProtocol? { get }
    var subNodes: [URLServiceNodeProtocol] { get }
    func registe(subNode: URLServiceNodeProtocol) -> Void
    func registeSubNode(with name: String, type: URLServiceNodeType) -> URLServiceNodeProtocol
    
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
    func setParams(_ params: Any?) -> Void
    func meetTheExecutionConditions() -> URLServiceErrorProtocol?
    func execute() -> ((_ object: Any?) -> Void)?
}

public protocol URLServiceErrorProtocol {
    var code: String { get }
    var content: String { get }
}
