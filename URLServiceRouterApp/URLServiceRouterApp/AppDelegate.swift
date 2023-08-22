//
//  AppDelegate.swift
//  URLServiceRouterDemo
//
//  Created by huanyu.li on 2021/8/4.
//

import UIKit
import URLServiceRouter

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        congifURLServiceRouter()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        window?.makeKeyAndVisible()
        
        window?.rootViewController = UINavigationController(rootViewController: ViewController())
        return true
    }
    
    func congifURLServiceRouter() {
        URLServiceRouter.shared.delegate = URLServiceRouterDelegate()
        URLServiceRouter.shared.rootNodeParsersBuilder = { [URLServiceRedirectHttpParser()] }
        registerServices()
        registerNodes()
    }
    
    func registerServices() {
        URLServiceRouter.shared.registerService(name: "user://info") {
            URLOwnerInfoService()
        }
        URLServiceRouter.shared.registerService(name: "input_page") {
            InputPageService()
        }
        
        URLServiceRouter.shared.registerService(name: "login") {
            LoginPageService()
        }
        
        URLServiceRouter.shared.registerService(name: "user_center") {
            UserService()
        }
    }
    
    func registerNodes() {
        URLServiceRouter.shared.registerNode(from: "https") {
            [URLServiceRedirectTestHostParser()]
        }
        
        do {
            URLServiceRouter.shared.registerNode(from: "https://www.realword.com/owner/info") {
                [URLServiceNoramlParser(parserType: .post, parseBlock: { nodeParser, _, decision in
                    decision.complete(nodeParser, "user://info")
                })]
            }
        }

        do {
            URLServiceRouter.shared.registerNode(from: "https://www.realword.com/owner/") {
                let preParser = URLServiceNoramlParser(parserType: .pre, parseBlock: { nodeParser, request, decision in
                    var nodeNames = request.nodeNames
                    if let first = nodeNames.first, first.isPureInt {
                        request.merge(params: ["id": nodeNames.remove(at: 0)], from: nodeParser)
                        request.replace(nodeNames: nodeNames, from: nodeParser)
                    }
                    decision.next()
                })
                
                let postParser = URLServiceNoramlParser(parserType: .post, parseBlock: { _, _, decision in
                    decision.next()
                })
                return [preParser, postParser]
            }
        }
        
        URLServiceRouter.shared.registerNode(from: "https://www.realword.com/company/work")
    }
}
