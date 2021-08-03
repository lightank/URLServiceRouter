//
//  URLService.swift
//  URLServiceRouterDemo
//
//  Created by huanyu.li on 2021/8/3.
//

import Foundation

class URLService: URLServiceProtocol {
    let name: String
    private var params: Any?
    
    func setParams(_ params: Any?) {
        
    }
    
    func meetTheExecutionConditions() -> URLServiceErrorProtocol? {
        return nil
    }
    
    func execute() -> ((Any?) -> Void)? {
        return nil
    }
    
    init(name: String) {
        self.name = name
    }
}
