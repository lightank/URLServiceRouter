//
//  URLFlatRounter.swift
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/1/29.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

import Foundation

@objc(LTURLFlatRounter) public class URLFlatRounter: NSObject, URLRounterProtocol {
    @objc public static let sharedInstance = URLFlatRounter()
    private(set) public var subModules: [String : URLModuleProtocol] = [:]
    
    @objc public func registeModules(pathComponents: [String], handleURLBlock: @escaping (_ url: URL) -> Void) {
        if (pathComponents.count == 0) {
            return;
        }
        
        var currentModule: URLModule? = nil
        pathComponents.forEach { (pathComponent) in
            assert(pathComponent.count > 0, "注册的模块名字不能为空,请检测")
            if currentModule == nil {
                var subModule = subModules[pathComponent]
                if subModule == nil {
                    subModule = URLModule.init(name: pathComponent, parentModule: nil)
                    registe(subModule: subModule!)
                }
                currentModule = subModule as! URLModule?;
            } else {
                var subModule = currentModule!.subModules[pathComponent]
                if subModule == nil {
                    subModule = URLModule.init(name: pathComponent, parentModule: currentModule)
                    currentModule?.registe(subModule: subModule!)
                }
                currentModule = subModule as! URLModule?;
            }
            
            if (pathComponent == pathComponents.last && currentModule != nil) {                
                currentModule!.canHandleURLBlock = { (url: URL) in
                    return true
                }
                
                currentModule!.handleURLBlock = { (url: URL) in
                    handleURLBlock(url)
                }
            }
        }
    }
    
    private func registe(subModule: URLModuleProtocol) {
        assert(subModule.name.count > 0, "注册的模块名字不能为空,请检测")
        if subModules[subModule.name] != nil {
            assert(false, "路由中心中的子模块:\(subModule.name) 已经被注册过了,请检测");
        } else {
            subModules[subModule.name] = subModule
        }
    }
    
    @objc public func unregiste(subModuleName: String) {
        assert(subModuleName.count > 0, "取消注册的模块名字不能为空,请检测");
        
        if subModules[subModuleName] != nil {
            subModules.removeValue(forKey: subModuleName)
        } else {
            print("路由中心中的子模块:\(subModuleName) 尚未注册或已经被移除,请检测");
        }
    }
    
    @objc public func bestModuleFor(url: URL) -> URLModuleProtocol? {
        if (url.absoluteString.count == 0 || url.pathComponents.count == 0) {
            return nil
        }
        
        let pathComponents = url.pathComponents
        var bestModule: URLModule? = nil
        pathComponents.forEach { (pathComponent) in
            var subModule: URLModule? = nil
            if (bestModule == nil) {
                if subModules[pathComponent] != nil {
                    subModule = subModules[pathComponent] as! URLModule?
                }
            } else {
                if bestModule!.subModules[pathComponent] != nil {
                    subModule = bestModule!.subModules[pathComponent] as! URLModule?
                }
            }
            
            if (subModule != nil) {
                bestModule = subModule
            }
        }
        
        return bestModule;
    }
    
    @objc public func handle(url: URL) {
        if let bestModule = bestModuleFor(url: url) {
            bestModule.moduleChainHandleBlock(url)
        }
    }
}
