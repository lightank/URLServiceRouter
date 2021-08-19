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
        
        window = UIWindow.init(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        window?.makeKeyAndVisible()

        window?.rootViewController = ViewController()
        return true
    }
    
    func congifURLServiceRouter() -> Void {
        URLServiceRouter.share.config(delegate: URLServiceRouterDelegate())
        URLServiceRouter.share.register(service: URLOwnerInfoService())
        
        URLServiceRouter.share.registerNode(from: "https", parsers:[URLServiceRedirectTestHostParser()]);
        
        do {
            let parser = URLServiceNoramlParser(parserType: .post, parseBlock: { (nodeParser, request, currentNode, decision) in
                decision.complete("user://info")
            })
             
            URLServiceRouter.share.registerNode(from: "https://www.realword.com/owner/info", parsers:[parser]);
        }

        do {
            let parser = URLServiceNoramlParser(parserType: .pre, parseBlock: { (nodeParser, request, currentNode, decision) in
                var nodeNames = request.nodeNames
                if let first = nodeNames.first, first.isPureInt {
                    request.merge(params: ["id": nodeNames.remove(at: 0)], from: nodeParser)
                    request.replace(nodeNames: nodeNames, from: nodeParser)
                }
                decision.next()
            })
             
            URLServiceRouter.share.registerNode(from: "https://www.realword.com/owner/", parsers:[parser]);
        }
        
        URLServiceRouter.share.registerNode(from: "https://www.realword.com/company/work");
    }
}

