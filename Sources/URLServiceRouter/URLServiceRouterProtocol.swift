//
//  URLRouterProtocol.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/1/28.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public let URLServiceRequestOriginalURLKey = "origin_request_url"
public let URLServiceNodeParserPriorityDefault = 100

public protocol URLServiceRouterDelegateProtocol {
    /// config service router's rootNode, eg: register Parser, register level one node
    /// - Parameter rootNode: service router's rootNode
    func rootNodeParsers() -> [URLServiceNodeParserProtocol]?
#if canImport(UIKit)
    /// return app's current viewController, when you need to show a new page, you may need this
    func currentViewController() -> UIViewController?
    /// return app's current NavigationController, when you need to show a new page, you may need this
    func currentNavigationController() -> UINavigationController?
#endif
    /// you can decide whether start this service request
    /// - Parameter request: a service request maybe start routering
    func shouldRouter(request: URLServiceRequestProtocol) -> URLServiceRequestProtocol?
    /// you can change the request‘s response service, or reject the result when finish the request routering
    /// - Parameters:
    ///   - request: current routering request
    ///   - service: final response service
    func dynamicProcessingRouterResult(request: URLServiceRequestProtocol, service: URLServiceProtocol?) -> URLServiceProtocol?
    /// log error, you may need record this to help solving problem
    /// - Parameter message: error message
    func logError(_ message: String) -> Void
    /// log info, you may need record this to help solving problem
    /// - Parameter message: info message
    func logInfo(_ message: String) -> Void
}

public protocol URLServiceRouterProtocol {
    /// delegate
    var delegate: URLServiceRouterDelegateProtocol? { get }
    /// config delegate
    /// - Parameter delegate: your delegate
    func config(delegate: URLServiceRouterDelegateProtocol) -> Void
    
    /// start router a given request. Generally speaking, it is handled by nodeTree
    /// - Parameter request: request need to router
    func router(request: URLServiceRequestProtocol) -> Void
    /// register a node chain from a node name array, and the end node will register all parsers in the parser array
    /// - Parameters:
    ///   - names: a string array storing node name
    ///   - parsers: a parser array for end node to register
    func registerNode(from names: [String], parsers: [URLServiceNodeParserProtocol]?)
    /// register a service
    /// - Parameter service: a service need to register
    func register(service: URLServiceProtocol) -> Void
    /// Check if there is a service with the given name
    /// - Parameter name: a given service name
    func isServiceValid(with name: String) -> Bool
    /// call service when the given service name is valid
    /// - Parameters:
    ///   - name: a given service name
    ///   - params: request params
    ///   - completion: a completion callback when finishing searching service
    ///   - callback: service callback block, you will get the response data
    func callService(name: String, params: Any?, completion: ((URLServiceProtocol?, URLServiceErrorProtocol?) -> Void)?, callback: URLServiceExecutionCallback?) -> Void
    
    /// return the urls of all registered nodes in an array
    func allRegistedNodeUrls() -> [String]
    /// return the names of all registered services in an array
    func allRegistedServiceNames() -> [String]
    
    /// log error, hand over the information to the delegate internally
    /// - Parameter message: error message
    func logError(_ message: String) -> Void
    /// log info, hand over the information to the delegate internally
    /// - Parameter message: info message
    func logInfo(_ message: String) -> Void
    
    /// test the parsing process and result of the request whether meets expectations, the service of result will not be executed
    /// - Parameters:
    ///   - url: request url
    ///   - shouldDelegateProcessingRouterResult: decide whether router delegate process router result
    ///   - completion: a completion callback when finishing searching service
    func unitTestRequest(url: String, shouldDelegateProcessingRouterResult: Bool, completion: @escaping ((URLServiceRequestProtocol, URLServiceRouterResultProtocol) -> Void)) -> Void
}

public protocol URLServiceRouterResultProtocol {
    /// the last node of matching node chain
    var endNode: URLServiceNodeProtocol? { get }
    /// the node that finally gives the response result
    var responseNode: URLServiceNodeProtocol? { get }
    /// the  name of the response service
    var responseServiceName: String? { get }
    
    /// record end node
    var recordEndNode: ((URLServiceNodeProtocol) -> Void) { get }
    /// record response node when the routing ends. if no node response, it will  be the root node
    var routerCompletion: ((URLServiceNodeProtocol, String?) -> Void) { get }
    /// a completion block when the routing ends. we notify request here
    var completion: ((URLServiceRouterResultProtocol) -> Void) { get }
}

public typealias URLServiceRequestCompletionBlock = (URLServiceRequestProtocol) -> Void
public protocol URLServiceRequestProtocol {
    /// request url
    var url: URL { get }
    /// The service router that will handle the request
    var serviceRouter: URLServiceRouterProtocol { get }
    /// It will constantly change during the node parsing process, it always represents the path array behind the current node
    /// eg: https://www.example.com/path/to/myfile, if current node is “path” ,it will be [“to”, “myfile”]
    var nodeNames: [String] { get }
    /// response model, it contains response service, response error, response data
    var response: URLServiceRequestResponseProtocol? { get }
    /// a success block that will be executed when find a service to respond when the request is routed
    var success: URLServiceRequestCompletionBlock? { get }
    /// a failure block that will be executed when find no service to respond when the request is routed
    var failure: URLServiceRequestCompletionBlock? { get }
    /// a response data block that will be executed after the finded service executed
    var callback: URLServiceRequestCompletionBlock? { get }
    var description: String { get }
    
    /// a completion block  that will be executed when service router finishing request routering
    /// - Parameter response: response model
    func completion(response: URLServiceRequestResponseProtocol) -> Void
    /// request parameters provided to the service
    func requestParams() -> Any?
    /// process the request to replace the current service request‘s nodeNames from a node parser
    /// - Parameters:
    ///   - nodeNames: a nodeNames array from  node parser
    ///   - nodeParser: a node parser that wants change current service request’s nodeNames
    func replace(nodeNames: [String], from nodeParser: URLServiceNodeParserProtocol ) -> Void
    /// delete the first element of nodeNames in the searching process (build the response node chain)
    /// - Parameter node: the current node in the searching process
    func reduceOneNodeName(from node: URLServiceNodeProtocol) -> Void
    /// add the  the previous node name  to nodeNames  during the backtracking process
    /// - Parameter node: The current node in the backtracking process
    func restoreOneNodeName(from node: URLServiceNodeProtocol) -> Void
    /// merge request parameter from a node parser
    /// - Parameters:
    ///   - params: a params need to merge
    ///   - nodeParser: a node parser that wants merge request parameter
    func merge(params: Any, from nodeParser: URLServiceNodeParserProtocol) -> Void
    /// replace request parameter from a node parser
    /// - Parameters:
    ///   - params: a params that will replace request parameter
    ///   - nodeParser: a node parser that wants replace request parameter
    func replace(params: Any?, from nodeParser: URLServiceNodeParserProtocol) -> Void
    
    /// start current service request. If you are concerned about the request result and callback, please set the corresponding block
    /// - Parameters:
    ///   - success: success block
    ///   - failure: failure block
    ///   - callback: callback block
    func start(success: URLServiceRequestCompletionBlock?, failure: URLServiceRequestCompletionBlock?, callback: URLServiceRequestCompletionBlock?) -> Void
    /// stop current service request.
    func stop() -> Void
}

public protocol URLServiceRequestResponseProtocol {
    var service: URLServiceProtocol? { get }
    var error: URLServiceErrorProtocol? { get }
    var data: Any? { get set }
}

/// node parser type. The pre-type parser works during the lookup, the post-type parser works during the backtracking process
public enum URLServiceNodeParserType: String {
    case pre = "pre"
    case post = "post"
}

public protocol URLServiceNodeParserProtocol {
    /// priority determines the order of execution, the higher the priority, the first to be executed. default value is 100
    var priority: Int { get }
    /// parser type,decide which process to work in
    var parserType: URLServiceNodeParserType { get }
    /// parse service request, you may change request requestParams or nodeNames here
    /// - Parameters:
    ///   - request: current service request,
    ///   - currentNode: current node that is processing the request
    ///   - decision: decision of current node parser
    func parse(request: URLServiceRequestProtocol, currentNode: URLServiceNodeProtocol, decision: URLServiceNodeParserDecisionProtocol) -> Void
}

public protocol URLServiceNodeParserDecisionProtocol {
    /// Go to the next step
    var next: (() -> Void) { get }
    /// end the processing and inform the hit service name
    var complete: ((String) -> Void) { get }
}

public protocol URLServiceNodeProtocol {
    /// node name, maybe represent one component in the URL or the root node
    var name: String { get }
    
    /// parent node, the backtracking process depends on this
    var parentNode: URLServiceNodeProtocol? { get }
    /// sub nodes, the search process may pick one of them as the next node
    var subNodes: [URLServiceNodeProtocol] { get }
    /// registe subNode
    /// - Parameter subNode: subNode
    func registe(subNode: URLServiceNodeProtocol) -> Void
    /// registe subNode with name and type
    /// - Parameters:
    ///   - name: subNode name
    ///   - type: subNode type
    func registeSubNode(with name: String) -> URLServiceNodeProtocol
    
    /// The parser arrar will be executed in the search process, the higher the priority, the first to execute
    var preParsers: [URLServiceNodeParserProtocol] { get }
    /// The parser arrar will be executed in the backtracking process, the higher the priority, the first to execute
    var postParsers: [URLServiceNodeParserProtocol] { get }
    /// registe parser
    /// - Parameter parser: parser
    func registe(parser: URLServiceNodeParserProtocol) -> Void
    
    /// router request and give your result
    /// - Parameters:
    ///   - request: request
    ///   - result: result
    func router(request: URLServiceRequestProtocol, result: URLServiceRouterResultProtocol) -> Void
    /// execute the pre-parsers and give your result during the searching process
    /// - Parameters:
    ///   - request: request
    ///   - result: result
    func routerPreParser(request: URLServiceRequestProtocol, result: URLServiceRouterResultProtocol) -> Void
    /// execute the post-parsers and give your result during the searching process
    /// - Parameters:
    ///   - request: request
    ///   - result: result
    func routerPostParser(request: URLServiceRequestProtocol, result: URLServiceRouterResultProtocol) -> Void
    /// current node chain name array
    func routedNodeNames() -> [String]
}

public typealias URLServiceExecutionCallback = (Any?) -> Void

public protocol URLServiceProtocol {
    /// service name
    var name: String { get }
    /// set  params
    /// - Parameter params: params
    func setParams(_ params: Any?) -> Void
    /// check whether the execution conditions are met
    func meetTheExecutionConditions() -> URLServiceErrorProtocol?
    /// execute current service, you need to decide for yourself whether to execute if the execution conditions are not met
    /// - Parameter callback: callback block, you can pass the response data
    func execute(callback: URLServiceExecutionCallback?) -> Void
}

public protocol URLServiceErrorProtocol {
    /// error code
    var code: String { get }
    /// error message
    var message: String { get }
}
