//
//  Demo.swift
//  URLServiceRouterDemo
//
//  Created by huanyu.li on 2021/8/3.
//

/*
 我们假设我们在一个真实世界服务器里，正式服务器是：www.realword.com，测试服务器是：*.realword.io
 */

import Foundation
import UIKit
import URLServiceRouter

class URLOwnerInfoService: URLServiceProtocol {
    let name: String = "user://info"
    private var ownders: [User] = [User(name: "神秘客", id: "1"), User(name: "打工人", id: "999"),]
    private var id: String?
    
    func setParams(_ params: Any?) {
        if params is [String: Any], let newId = (params as! [String : Any])["id"] {
            id = newId as? String
        } else if params is String? {
            id = params as? String
        }
    }
    
    func meetTheExecutionConditions() -> URLServiceErrorProtocol? {
        if id == nil {
            return URLServiceError(code: "1111", message: "no id to accsee owner info")
        }
        return nil
    }
    
    func execute(callback: ((_ object: Any?) -> Void)?) -> Void {
        if (meetTheExecutionConditions() != nil) {
            return
        }
        
        let userInfoCallback = {
            if let newId = self.id {
                if let newCallback = callback {
                    newCallback(self.findUser(with: newId))
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            userInfoCallback()
        }
    }
    
    func findUser(with id: String) -> User? {
        return ownders.first { $0.id == id}
    }
}

struct User {
    var name: String
    var id: String
    init(name: String, id: String) {
        self.name = name
        self.id = id
    }
}

class URLServiceRouterDelegate: URLServiceRouterDelegateProtocol {
    func currentViewController() -> UIViewController? {
        var topViewController = UIApplication.shared.delegate?.window??.rootViewController
        while let viewController = topViewController?.presentedViewController {
            topViewController = viewController
        }
        while let viewController = topViewController,
              viewController is UINavigationController,
              let navigationController = viewController as? UINavigationController,
              let topVC = navigationController.topViewController  {
            topViewController = topVC
        }
        return topViewController
    }
    
    func currentNavigationController() -> UINavigationController? {
        return currentViewController()?.navigationController
    }
    
    func shouldRouter(request: URLServiceRequestProtocol) -> Bool {
        return true
    }
    
    func dynamicProcessingRouterRequest(_ request: URLServiceRequestProtocol) {
        
    }
    
    func rootNodeParsers() -> [URLServiceNodeParserProtocol]? {
        return [URLServiceRedirectHttpParser()]
    }
    
    func logError(_ message: String) {
        print("❌URLServiceRouter log error start: \n\(message)\n❕URLServiceRouter log error end❌")
    }
    
    func logInfo(_ message: String) {
        print("❕URLServiceRouter log info start: \n\(message)\n❕URLServiceRouter log info end❕")
    }
}

struct URLServiceRedirectTestHostParser :URLServiceNodeParserProtocol {
    let priority: Int = URLServiceNodeParserPriorityDefault
    var parserType: URLServiceNodeParserType = .pre
    
    func parse(request: URLServiceRequestProtocol, decision: URLServiceNodeParserDecisionProtocol) {
        if let host = request.url.host, request.nodeNames.contains(host), host.isTestHost {
            var nodeNames = request.nodeNames
            nodeNames.remove(at: 0)
            nodeNames.insert(String.productionHost, at: 0)
            request.replace(nodeNames: nodeNames, from: self)
        }
        decision.next();
    }
}

extension String {
    var isTestHost: Bool {
        return hasSuffix(".realword.io")
    }
    
    static var productionHost: String {
        return "www.realword.com"
    }
    
    var isPureInt: Bool {
        let scanner = Scanner(string: self)
        var value: UnsafeMutablePointer<Int>?
        return scanner.scanInt(value) && scanner.isAtEnd
    }
}

public struct URLServiceRedirectHttpParser :URLServiceNodeParserProtocol {
    public let priority: Int = URLServiceNodeParserPriorityDefault
    public var parserType: URLServiceNodeParserType = .pre
    
    public func parse(request: URLServiceRequestProtocol, decision: URLServiceNodeParserDecisionProtocol) {
        if let scheme = request.url.scheme, scheme == "http", request.nodeNames.contains(scheme) {
            var nodeNames = request.nodeNames
            nodeNames.remove(at: 0)
            nodeNames.insert("https", at: 0)
            request.replace(nodeNames: nodeNames, from: self)
        }
        decision.next();
    }
}
