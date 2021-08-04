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

class URLOwnerInfoService: URLServiceProtocol {
    let name: String = "user://info"
    private var ownders: [User] = [User(name: "神秘客", id: "1"), User(name: "打工人", id: "999"),]
    private var params = [String: Any]()
    
    func setParams(_ params: Any?) {
        if params is [String: Any] {
            self.params.merge(params as! [String : Any]) {(current, _) in current}
        }
    }
    
    func meetTheExecutionConditions() -> URLServiceErrorProtocol? {
        if params["id"] == nil{
            return URLServiceError(code: "1111", content: "no id to accsee owner info")
        }
        return nil
    }
    
    func execute(callback: ((_ object: Any?) -> Void)?) -> Void {
        if (meetTheExecutionConditions() != nil) {
            return
        }
        
        let userInfoCallback = {
            if let id = self.params["id"], id is String {
                if let newCallback = callback {
                    newCallback(self.findUser(with: id as! String))
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
    let rootNodeParsers: [URLServiceNodeParserProtocol] = [URLServiceRedirectHttpParser()]
    
    func configRootNode(_ rootNode: URLServiceNodeProtocol) -> Void {
        rootNode.registe(parser: URLServiceRedirectHttpParser())
        registerlevelOneNodes(with: rootNode)
    }
    
    func registerlevelOneNodes(with rootNode: URLServiceNodeProtocol) -> Void {
        let httpsNode = URServiceNode(name: "https", nodeType: .scheme, parentNode: rootNode)
        httpsNode.registe(parser: URLServiceRedirectTestHostParser())
        rootNode.registe(subNode: httpsNode)
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
    
    func parse(request: URLServiceRequestProtocol, currentNode: URLServiceNodeProtocol, decision: URLServiceNodeParserDecisionProtocol) {
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
}
