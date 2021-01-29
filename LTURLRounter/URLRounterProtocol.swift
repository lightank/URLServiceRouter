//
//  URLRounterProtocol.swift
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/1/28.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

import Foundation

@objc(LTURLRounterProtocol) public protocol URLRounterProtocol: AnyObject {

    /// 所有的子模块，注意：注册、取消注册模块方法需要自己定义，这个并不提供
    var subModules: [String: URLModuleProtocol] { get }
    
    /// 找到最适合处理这个url的模块，如果没有就返回nil
    /// - Parameter url: url
    func bestModuleFor(url: URL) -> URLModuleProtocol?
    
    /// 处理url
    /// - Parameter url: url
    func handle(url: URL) -> Void
}

@objc(LTURLModuleProtocol) public protocol URLModuleProtocol {
    
    /// 模块名称
    var name: String { get }
    /// 父模块
    weak var parentModule: URLModuleProtocol? { get }
    /// 所有子模块
    var subModules: [String: URLModuleProtocol] { get }
    /// 当前模块是否可以解析这个URL，如果可以就返回 true，不能就返回 false
    var canHandleURLBlock: ((_ url: URL) -> Bool) { get set }
    /// 当前模块处理url
    var handleURLBlock: ((_ url: URL) -> Void) { get set }
    /// 模块链是否可以解析这个URL，如果可以就返回 true，不能就返回 false
    var canModuleChainHandleBlock: ((_ url: URL) -> Bool) { get set }
    /// 模块链处理url
    var moduleChainHandleBlock: ((_ url: URL) -> Void) { get set }
        
    /// 注册子模块
    /// - Parameter subModule: 子模块
    func registe(subModule: URLModuleProtocol) -> Void
    
    /// 取消注册子模块
    /// - Parameter subModuleName: 子模块名称
    func unregiste(subModuleName: String) -> Void
}
