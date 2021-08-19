//
//  ViewController.swift
//  URLServiceRouterDemo
//
//  Created by huanyu.li on 2021/8/4.
//

import UIKit
import URLServiceRouter

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if let url = URL(string: "http://china.realword.io/owner/1/info") {
            URLServiceRequest(url: url).start(callback: { (request) in
                 if let data = request.response?.data {
                    if data is URLServiceErrorProtocol {
                        // 遇到错误了

                    } else {
                        // 正确的数据
                        
                    }
                }
                URLServiceRouter.share.logInfo("\(String(describing: request.response?.data))")
            })
        }
        
        URLServiceRouter.share.callService(name: "user://info", params: "1") { (service, error) in
            
        } callback: { (result) in
            URLServiceRouter.share.logInfo("\(String(describing: result))")
        }
        
        URLServiceRouter.share.unitTestRequest(url: "http://china.realword.io/owner/1/info") { (request, routerResult) in
            URLServiceRouter.share.logInfo("\(String(describing: request.response?.data))")
        }
    }
}

