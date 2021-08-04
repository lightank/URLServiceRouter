//
//  ViewController.swift
//  URLServiceRouterDemo
//
//  Created by huanyu.li on 2021/8/2.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        URLServiceRouter.share.register(service: URLOwnerInfoService())
        
        URLServiceRouter.share.registerNode(from: "https://www.realword.com/owner/") { (node) in
            node.registe(parser: URLServiceNoramlParser(parserType: .pre, parseBlock: { (nodeParser, request, currentNode, decision) in
                var nodeNames = request.nodeNames
                if !nodeNames.isEmpty {
                    request.merge(params: ["id": nodeNames.remove(at: 0)], from: nodeParser)
                }
                request.replace(nodeNames: nodeNames, from: nodeParser)
                decision.next()
            }))
        }
        
        URLServiceRouter.share.registerNode(from: "https://www.realword.com/owner/info") { (node) in
            node.registe(parser: URLServiceNoramlParser(parserType: .pre, parseBlock: { (nodeParser, request, currentNode, decision) in
                decision.complete("user://info")
            }))
        }
        
        URLServiceRouter.share.registerNode(from: "https://www.realword.com/company/work") { (node) in
            
        }
        
        if let url = URL(string: "http://china.realword.io/owner/1/info") {
            URLServiceRequest(url: url).start { (request) in
                
            } failure: { (request) in
                
            } serviceCallback: { (result) in
                
            }
        }
    }
    
    func testURLServiceRouter() {
        
    }
}

