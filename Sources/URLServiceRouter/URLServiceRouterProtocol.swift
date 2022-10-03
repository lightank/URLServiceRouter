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

// MARK: - URLServiceRouterDelegate

public protocol URLServiceRouterDelegateProtocol {
    /// 返回将要在根节点中注册的解析器数组
    func rootNodeParsers() -> [URLServiceNodeParserProtocol]?
    
    // MARK: 控制器信息
    
#if canImport(UIKit)
    /// 返回 app 当前的显示的 vc，方便页面级的 URLService 进行跳转
    func currentViewController() -> UIViewController?
    /// 返回 app 当前的显示的 vc 所在的导航控制器，方便页面级的 URLService 进行跳转
    func currentNavigationController() -> UINavigationController?
#endif
    
    // MARK: 服务请求
    
    /// 拦截并决定是否发起此次 URLServiceRouter 中的服务路由请求
    /// - Parameter request: 当前 URLServiceRouter 将要发起的服务请求
    func shouldRoute(request: URLServiceRequestProtocol) -> Bool
    /// 动态处理服务请求结果
    /// - Parameters:
    ///   - request: 当前的服务请求
    func dynamicProcessingServiceRequest(_ request: URLServiceRequestProtocol)
    
    // MARK: 日志
    
    /// 记录从 URLServiceRouter 来的错误日志
    /// - Parameter message: error message
    func logError(_ message: String)
    /// 记录从 URLServiceRouter 来的普通日志
    /// - Parameter message: info message
    func logInfo(_ message: String)
}

// MARK: - URLServiceRouter

public protocol URLServiceRouterProtocol {
    // MARK: 代理
    
    /// 代理，提供：当前vc信息、拦截请求、动态处理请求结果、记录日志等功能
    var delegate: URLServiceRouterDelegateProtocol? { get }
    /// 配置代理
    /// - Parameter delegate: 代理
    func config(delegate: URLServiceRouterDelegateProtocol)
    
    // MARK: node
    
    /// 从字符串 url 中注册一个 node chain，并在 endNode 中注册解析器数组。如果除 endNode 外的 node 如果已经存在，将不会重复注册，仅取值
    /// - Parameters:
    ///   - url: 字符串 url
    ///   - parsersBuilder: 将在 endNode 中注册解析器数组 Builder
    func registerNode(from url: String, parsersBuilder: (() -> [URLServiceNodeParserProtocol])?)
    /// 检测给的名称的node url字符串是否注册过
    /// - Parameter url: node url字符串
    func isRegisteredNode(_ url: String) -> Bool
    /// 返回所有已经注册过的 node URL 数组
    func allRegisteredNodeUrls() -> [String]
    
    // MARK: 服务
    
    /// 注册服务
    /// - Parameter name: 服务名称
    /// - Parameter builder: 构造器
    func registerService(name: String, builder: @escaping () -> URLServiceProtocol)
    
    /// 调用服务
    /// - Parameters:
    ///   - name: 服务名称
    ///   - params: 请求参数
    ///   - completion: 路由完成回调，如果服务存在，将在 completion 后真正开始调用服务
    ///   - callback: 服务调用完成回调，如果关注服务调用结果的话，应该给它赋值
    func callService(name: String, params: Any?, completion: ((URLServiceProtocol?, URLServiceErrorProtocol?) -> Void)?, callback: URLServiceExecutionCallback?)
    /// 检测给定的服务名称对应的服务是否有注册
    /// - Parameter name: 服务名称
    func isRegisteredService(_ name: String) -> Bool
    /// 返回所有已经注册过的服务的名称数组
    func allRegisteredServiceNames() -> [String]
    
    // MARK: 服务请求
    
    /// 路由一个服务请求
    /// - Parameter request: 服务请求
    func route(request: URLServiceRequestProtocol)
    
    /// 能否处理给定 url，即 url 是否有命中的服务
    /// - Returns: true 代表可处理，false 代表不可处理
    func canHandleUrl(url: String) -> Bool
    
    // MARK: 日志
    
    /// 记录错误日志，内部会交给代理处理
    /// - Parameter message: 信息内容
    func logError(_ message: String)
    /// 记录普通日志，内部会交给代理处理
    /// - Parameter message: 信息内容
    func logInfo(_ message: String)
    
    // MARK: 测试
    
    /// 测试请求解析流程、是否达到服务调用条件，但并不会调用服务。注意：仅在 DEBUG 下执行
    /// - Parameters:
    ///   - url: 请求url
    ///   - shouldDelegateProcessingRouterResult: 代理是否处理请求结果
    ///   - completion: 完成请求命中服务的回调
    func unitTestRequest(url: String, shouldDelegateProcessingRouterResult: Bool, completion: @escaping ((URLServiceRequestProtocol, URLServiceRouteResultProtocol) -> Void))
}

// MARK: - URLServiceRouteResult

public protocol URLServiceRouteResultProtocol {
    /// 请求命中的  node chain 的 end node
    var endNode: URLServiceNodeProtocol? { get }
    /// 请求命中的  node chain 的最终响应的 node
    var responseNode: URLServiceNodeProtocol? { get }
    /// 给出请求结果的 node 解析器
    var responseNodeParser: URLServiceNodeParserProtocol? { get }
    /// 请求命中的服务名称
    var responseServiceName: String? { get }
    
    /// 记录 end node 的 block
    var recordEndNode: (URLServiceNodeProtocol) -> Void { get }
    /// 当请求路由完成的时候，记录最终响应的 node 回调。如果没有 node 响应，那么将记录 root node
    var routerCompletion: (URLServiceNodeProtocol, URLServiceNodeParserProtocol?, String?) -> Void { get }
    /// 请求路由完成回调，我们一般在这里通知请求
    var completion: (URLServiceRouteResultProtocol) -> Void { get }
}

// MARK: - URLServiceRequest

public typealias URLServiceRequestCompletionBlock = (URLServiceRequestProtocol) -> Void
public protocol URLServiceRequestProtocol {
    /// 请求 url
    var url: URL { get }
    /// 处理请求的服务路由器
    var serviceRouter: URLServiceRouterProtocol { get }
    /// 在节点解析过程中会不断变化，始终代表当前节点后面的路径字符串数组
    /// 例如: https://www.example.com/path/to/myfile, 如果当前节点名称是 “path” , 它的值将会是 [“to”, “myfile”]
    var nodeNames: [String] { get }
    /// 响应结果，包含：响应的服务、错误、数据
    var response: URLServiceRequestResponseProtocol? { get }
    /// 请求成功回调，当请求被路由时找到响应的服务将被执行
    var success: URLServiceRequestCompletionBlock? { get }
    /// 请求失败回调，当请求被路由时发现没有服务响应时将执行
    var failure: URLServiceRequestCompletionBlock? { get }
    /// 服务执行的回调，在响应的服务执行后会调用，如果没有服务命中将不会被调用
    var callback: URLServiceRequestCompletionBlock? { get }
    /// 当前请求的描述信息
    var description: String { get }
    /// 是否仅路由请求但并不执行服务，默认值为 false
    var isOnlyRouting: Bool { get }
    
    func updateResponse(_ response: URLServiceRequestResponseProtocol?)
    /// 在服务路由器完成请求路由时将执行的回调，您应该在调用此方法之前为 响应结果(response) 赋值
    func routingCompletion()
    /// 请求参数，一般是提供给命中的路由服务使用
    func requestParams() -> Any?
    
    /// 处理来自节点解析器的替换当前服务请求的节点名称的请求。一般来讲，我们只允许前置解析器的请求
    /// - Parameters:
    ///   - nodeNames: 节点解析器提供的节点名称数组
    ///   - nodeParser: 发起该修改的节点解析器
    func replace(nodeNames: [String], from nodeParser: URLServiceNodeParserProtocol)
    /// 路由查找过程中，删除当前请求 nodeNames 的第一个元素
    /// - Parameter node: 路由查找过程中的当前节点
    func reduceOneNodeName(from node: URLServiceNodeProtocol)
    /// 路由回溯过程中，将上一个节点名称添加到 nodeNames 中
    /// - Parameter node: 路由回溯过程中的当前节点
    func restoreOneNodeName(from node: URLServiceNodeProtocol)
    /// 合并某个节点解析器提供的请求参数到当前请求的请求参数。一般来讲，我们只允许前置解析器的请求
    /// - Parameters:
    ///   - params: 需要合并的参数
    ///   - nodeParser: 想要合并参数的节点解析器
    func merge(params: Any, from nodeParser: URLServiceNodeParserProtocol)
    /// 使用某个节点解析器提供的请求参数来代替当前请求的请求参数。一般来讲，我们只允许前置解析器的请求
    /// - Parameters:
    ///   - params: 节点解析器提供的将要代替当前请求参数的参数
    ///   - nodeParser: 发起修改参数的节点解析器
    func replace(params: Any?, from nodeParser: URLServiceNodeParserProtocol)
    
    /// 开始当前服务请求的路由，如果你需要关注请求结果，你需要为 callback 赋值
    /// - Parameters:
    ///   - success: 路由完成回调
    ///   - failure: 路由失败回调
    ///   - callback: 服务调用完成回调
    func start(success: URLServiceRequestCompletionBlock?, failure: URLServiceRequestCompletionBlock?, callback: URLServiceRequestCompletionBlock?)
    /// 停止当前请求，调用后将不会执行命中的服务
    func stop()
}

// MARK: - URLServiceRequestResponse

public protocol URLServiceRequestResponseProtocol {
    /// 响应的服务名称
    var serviceName: String? { get set }
    /// 错误信息，比如：不满足执行条件时返回的错误、找不到服务的错误、服务执行的错误等
    var error: URLServiceErrorProtocol? { get set }
    /// 响应的数据
    var data: Any? { get set }
}

// MARK: - URLServiceNode

public protocol URLServiceNodeProtocol {
    /// 节点名称，可能代表根节点或者 URL 中的一个 components 的某一个元素
    var name: String { get }
    
    /// 父节点，将在路由回溯中用到
    var parentNode: URLServiceNodeProtocol? { get }
    /// 注册子节点
    /// - Parameter subNode: 子节点
    func registe(subNode: URLServiceNodeProtocol)
    /// 使用名称注册子节点
    /// - Parameters:
    ///   - name: 子节点名称
    func registeSubNode(with name: String) -> URLServiceNodeProtocol
    
    /// 解析器数组 builder，在初次解析url时调用去注册解析器。用于懒加载解析器数组
    var parsersBuilder: (() -> [URLServiceNodeParserProtocol])? { get set }
    /// 前序解析器数组，将在路由查找过程中执行，优先级越高越先被执行
    var preParsers: [URLServiceNodeParserProtocol] { get }
    /// 后序解析器数组，将在路由回溯过程中执行，优先级越高越先被执行
    var postParsers: [URLServiceNodeParserProtocol] { get }

    /// 注册解析器
    /// - Parameter parser: 解析器
    func register(parser: URLServiceNodeParserProtocol)
    
    /// 路由服务请求，并给出路由结果
    /// - Parameters:
    ///   - request: 服务请求
    ///   - result: 路由结果
    func route(request: URLServiceRequestProtocol, result: URLServiceRouteResultProtocol)
    /// 执行前序解析器，并给出结果。注意：这个是在路由查找过程中执行
    /// - Parameters:
    ///   - request: 服务请求
    ///   - result: 路由结果
    func routePreParser(request: URLServiceRequestProtocol, result: URLServiceRouteResultProtocol)
    /// 执行后序解析器，并给出结果。注意：这个是在路由回溯过程中执行
    /// - Parameters:
    ///   - request: 服务请求
    ///   - result: 路由结果
    func routePostParser(request: URLServiceRequestProtocol, result: URLServiceRouteResultProtocol)
    /// 从根节点到当前节点的 节点链(node chain)  中所有节点名称数组（根节点名称是第一个原生）
    func routedNodeNames() -> [String]
}

// MARK: - URLServiceNodeParser

/// 节点解析器类型，pre-type 解析器在路由查找过程中执行，post-type 解析器在路由回溯过程中执行
public enum URLServiceNodeParserType: String {
    case pre
    case post
}

// MARK: - URLServiceNodeParser

public protocol URLServiceNodeParserProtocol {
    /// 优先级，决定执行顺序，优先级越高越先被执行，默认值是100
    var priority: Int { get }
    /// 解析器类型，决定在哪个流程中执行，前序解析器在路由查找过程中执行，后续解析器在路由回溯过程中执行
    var parserType: URLServiceNodeParserType { get }
    /// 解析服务请求，可以改名请求参数、请求的 nodeNames （可以改变下一个节点）
    /// - Parameters:
    ///   - request: 服务请求
    ///   - decision: 解析器给出的决定
    func parse(request: URLServiceRequestProtocol, decision: URLServiceNodeParserDecisionProtocol)
}

// MARK: - URLServiceNodeParserDecision

public protocol URLServiceNodeParserDecisionProtocol {
    /// 通知解析器执行下一步
    var next: () -> Void { get }
    /// 通知节点解析器命中的服务名称回调
    var complete: (URLServiceNodeParserProtocol, String) -> Void { get }
}

// MARK: - URLService

public typealias URLServiceExecutionCallback = (Any?, URLServiceErrorProtocol?) -> Void
public protocol URLServiceProtocol {
    /// 是否满足服务执行条件
    func meetTheExecutionConditions(params: Any?) -> URLServiceErrorProtocol?
    /// 执行当前服务，你可能需要自行决定在不满足执行条件时是否执行服务
    /// - Parameter params: 执行的参数
    /// - Parameter callback: 完成回调
    func execute(params: Any?, callback: URLServiceExecutionCallback?)
}

// MARK: - URLServiceError

public protocol URLServiceErrorProtocol {
    /// 错误码
    var code: String { get }
    /// 错误信息
    var message: String { get }
}
