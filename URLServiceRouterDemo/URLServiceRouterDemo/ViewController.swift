//
//  ViewController.swift
//  URLServiceRouterDemo
//
//  Created by huanyu.li on 2021/8/4.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if let url = URL(string: "http://china.realword.io/owner/1/info") {
            URLServiceRequest(url: url).start { (request) in
                
            } failure: { (request) in
                
            } serviceCallback: { (result) in
                URLServiceRouter.share.logInfo("\(String(describing: result))")
            }
        }
        
        URLServiceRouter.share.callService(name: "user://info", params: "1") { (service, error) in
            
        } callback: { (result) in
            
        }

    }
}

