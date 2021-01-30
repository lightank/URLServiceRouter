//
//  SwiftDemo.swift
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/1/29.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

import Foundation

@objc(LTSwiftDemo) public class SwiftDemo: NSObject {
    @objc public static func testRounter() {
        testSwiftRounter()
    }
    
    static func testSwiftRounter() {
        URLFlatRounter.sharedInstance.registeModules(pathComponents: ["hotel", "detail"]) { (url) in
            print("跳转到酒店详情页")
        }

        URLFlatRounter.sharedInstance.registeModules(pathComponents: ["hotel"]) { (url) in
            print("跳转到酒店垂直页")
        }

        URLFlatRounter.sharedInstance.handle(url: URL.init(string: "https://www.klook.com/hotel/1234/detail")!)
        URLFlatRounter.sharedInstance.handle(url: URL.init(string: "https://www.klook.com/hotel/1234/detail1")!)
        
        let url: URL = URL.init(string: "https://www.klook.com/hotel/1234/detail")!
        URLRounter.sharedInstance.registe(subModule: URLHandler())
        let bestModule = URLRounter.sharedInstance.bestModuleFor(url: url)
        bestModule?.handleURLBlock(url)
    }

    static func URLHandler() -> URLModule{
        let hotel: URLModule = URLModule.init(name: "hotel", parentModule: nil)
        
        let detail: URLModule = URLModule.init(name: "detail", parentModule: hotel)
        detail.canHandleURLBlock = {_ in true}
        detail.handleURLBlock = {(url: URL) in
            print("跳转到酒店详情页")
        }
        hotel.registe(subModule: detail)
        return hotel
    }
}
