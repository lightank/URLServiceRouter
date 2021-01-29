//
//  URLModule.swift
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/1/29.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

import Foundation

@objc(LTURLModule) public class URLModule: NSObject, URLModuleProtocol {
    
    public let name: String
    private(set) weak public var parentModule: URLModuleProtocol?
    private(set) public var subModules: [String : URLModuleProtocol] = [:]
    
    @objc public lazy var canHandleURLBlock: ((_ url: URL) -> Bool) = {_ in false}
    
    @objc public var handleURLBlock: ((_ url: URL) -> Void) = {_ in }
    
    @objc public lazy var canModuleChainHandleBlock: ((URL) -> Bool) = {(url: URL) in
        if (self.canHandleURLBlock(url)) {
            return true
        } else {
            var canHandleURL = false;
            var module:URLModuleProtocol? = self.parentModule;
            while (module != nil) {
                canHandleURL = module!.canHandleURLBlock(url)
                if (canHandleURL) {
                    break
                } else {
                    module = module?.parentModule
                }
            }
            
            return canHandleURL;
        }
    }
    
    @objc public lazy var moduleChainHandleBlock: ((URL) -> Void) = { (url: URL) in
        if (self.canModuleChainHandleBlock(url)) {
            if (self.canHandleURLBlock(url)) {
                self.handleURLBlock(url)
            } else {
                if let module = self.parentModule {
                    module.moduleChainHandleBlock(url)
                }
            }
        }
    }
    
    @objc public required init(name: String, parentModule: URLModuleProtocol?) {
        assert(name.count > 0, "注册的模块名字不能为空,请检测")
        self.name = name
        self.parentModule = parentModule
        
        super.init();
    }
    
    @objc public func registe(subModule: URLModuleProtocol) {
        assert(subModule.name.count > 0, "注册的模块名字不能为空,请检测")
        if subModules[subModule.name] != nil {
            assert(false, "模块:\(name) 中的子模块:\(subModule.name) 已经被注册过了,请检测");
        } else {
            subModules[subModule.name] = subModule
        }
    }
    
    @objc public func unregiste(subModuleName: String) {
        assert(subModuleName.count > 0, "取消注册的模块名字不能为空,请检测");
        
        if subModules[subModuleName] != nil {
            subModules.removeValue(forKey: subModuleName)
        } else {
            print("模块:\(name) 中的子模块:\(subModuleName) 尚未注册或已经被移除,请检测");
        }
    }
}
