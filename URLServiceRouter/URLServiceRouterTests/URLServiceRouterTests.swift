//
//  URLServiceRouterTests.swift
//  URLServiceRouterTests
//
//  Created by huanyu.li on 2021/8/19.
//

import XCTest
@testable import URLServiceRouter

class URLServiceRouterTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testRouter() throws {
        let service = URLService(name: "helloWorld", executeBlock:  { params, callBack  in
            print("helloWorld 参数：\(String(describing: params))")
            callBack?("helloWorld", nil)
        })
        URLServiceRouter.shared.register(service: service)
        XCTAssert(URLServiceRouter.shared.isRegisteredService(service.name), "服务：\(service.name)注册失败")
        
        let nodeParser = URLServiceNoramlParser(parserType: .pre) { parser, request, decision in
            request.merge(params: ["slogan": "just dance"], from: parser)
            decision.complete(parser, service.name)
        }
        let url = "https://hello/world?name=justDance"
        URLServiceRouter.shared.registerNode(from: url, parsers: [nodeParser])
        XCTAssert(URLServiceRouter.shared.isRegisteredNode(url), "node\(url)注册失败")
        
        if let newUrl = URL(string: url) {
            URLServiceRequest(url: newUrl).start { request in
                if let map = request.requestParams() as? Dictionary<String, Any> {
                    if let name = map["name"] as? String {
                        XCTAssert(name == "justDance", "返回结果不对")
                    }
                    if let requestUrl = map[URLServiceRequestOriginalURLKey] as? URL {
                        XCTAssert(requestUrl.absoluteString == request.url.absoluteString, "请求URL不对")
                    }
                    if let slogan = map["slogan"] as? String {
                        XCTAssert(slogan == "just dance", "node 解析器添加的参数不对")
                    }
                }
            } failure: { request in
                XCTAssert(false, "找到错误的服务了")
            } callback: { request in
                if let data = request.response?.data {
                    if data is URLServiceErrorProtocol {
                        // 遇到错误了
                    } else if let newData = data as? String {
                        XCTAssert(newData == "helloWorld", "返回结果不对")
                    }
                }
            }
        }
        
        if let newUrl = URL(string: "https://see/you/again") {
            URLServiceRequest(url: newUrl).start(success: { request in
                XCTAssert(false, "找到错误的服务了")
            }, failure: { request in
                if let data = request.response?.error {
                    XCTAssert(data.code == "404", "找到错误的服务了")
                }
            }, callback: { request in
                XCTAssert(false, "找到错误的服务了")
            })
        }
    }
}


typealias URLServiceExecuteConditionsBlock = (Any?) -> URLServiceErrorProtocol?
typealias URLServiceExecuteBlock = (Any?, URLServiceExecutionCallback?) -> Void
class URLService: URLServiceProtocol {
    var name: String
    var executeConditionsBlock: URLServiceExecuteConditionsBlock?
    var executeBlock: URLServiceExecuteBlock?
    
    public init(name: String, executeConditionsBlock: URLServiceExecuteConditionsBlock? = nil, executeBlock: URLServiceExecuteBlock? = nil) {
        self.name = name
        self.executeConditionsBlock = executeConditionsBlock
        self.executeBlock = executeBlock
    }
    
    func meetTheExecutionConditions(params: Any?) -> URLServiceErrorProtocol? {
        return executeConditionsBlock?(params)
    }
    
    func execute(params: Any?, callback: URLServiceExecutionCallback?) {
        executeBlock?(params, callback)
    }
}
