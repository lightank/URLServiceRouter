//
//  Demo.swift
//  URLServiceRouterDemo
//
//  Created by huanyu.li on 2021/8/3.
//

/*
 我们假设我们在一个真实世界服务器里，正式服务器是：www.realword.com，测试服务器是：*.realword.io
 */

import Foundation
import UIKit
import URLServiceRouter

class URLOwnerInfoService: URLServiceProtocol {
    func preServiceCallBack(name: String, result: Any?, error: URLServiceErrorProtocol?, decision: URLServiceDecisionProtocol) {
        decision.next()
    }
    
    
    func preServiceCallBack(name: String, result: Any?, decision: URLServiceDecisionProtocol) {
        decision.next()
    }
    
    func paramsForPreService(name: String) -> Any? {
        return nil
    }
    
    var preServiceNames: [String] = []

    
    let name: String = "user://info"
    private var ownders: [User] = [User(name: "神秘客", id: "1"), User(name: "打工人", id: "999")]

    func meetTheExecutionConditions(params: Any?) -> URLServiceErrorProtocol? {
        if getUserId(from: params) != nil {
            return nil
        } else {
            return URLServiceError(code: "1111", message: "no id to accsee owner info")
        }
    }

    func execute(params: Any?, callback: URLServiceExecutionCallback?) {
        if meetTheExecutionConditions(params: params) != nil {
            return
        }

        let userInfoCallback = {
            if let newId = self.getUserId(from: params) {
                callback?(self.findUser(with: newId), nil)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            userInfoCallback()
        }
    }

    func getUserId(from params: Any?) -> String? {
        var id: String?
        if params is [String: Any], let newId = (params as! [String: Any])["id"] {
            id = newId as? String
        } else if params is String? {
            id = params as? String
        }
        return id
    }

    func findUser(with id: String) -> User? {
        return ownders.first { $0.id == id }
    }
}

struct User {
    var name: String
    var id: String
    init(name: String, id: String) {
        self.name = name
        self.id = id
    }
}

public func screenSize() -> CGSize {
    return UIApplication.shared.keyWindow?.bounds.size ?? CGSize.zero
}

class InputPageService: URLServiceProtocol {
    func preServiceCallBack(name: String, result: Any?, error: URLServiceErrorProtocol?, decision: URLServiceDecisionProtocol) {
        decision.next()
    }
    func paramsForPreService(name: String) -> Any? {
        return nil
    }
    
    var preServiceNames: [String] = []
    
    func preServiceCallBack(name: String, result: Any?, decision: URLServiceDecision) {
        
    }
    
    var name: String = "input_page"

    func meetTheExecutionConditions(params: Any?) -> URLServiceErrorProtocol? {
        return nil
    }

    func execute(params: Any?, callback: URLServiceExecutionCallback?) {
        if let currentNavigationController = URLServiceRouter.shared.delegate?.currentNavigationController() {
            let inputViewController = InputViewController()
            inputViewController.placeholder = getPlaceholder(from: params)
            inputViewController.callBack = { result in
                callback?(result, nil)
            }
            currentNavigationController.pushViewController(inputViewController, animated: true)
        }
    }

    func getPlaceholder(from params: Any?) -> String? {
        var placeholder: String?
        if params is String? {
            placeholder = params as? String
        }
        return placeholder
    }
}

class InputViewController: UIViewController {
    public var placeholder: String?
    public var callBack: ((String?) -> Void)?
    lazy var textField: UITextField = {
        let textField = UITextField(frame: CGRect(x: 16, y: 100, width: screenSize().width - 2 * 16, height: 44))
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        return textField
    }()

    lazy var button: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.frame = CGRect(x: 16, y: 164, width: screenSize().width - 2 * 16, height: 44)
        button.setTitle("点击关闭页面并回传数据", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(didClickedButton), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "InputViewController"
        view.addSubview(textField)
        view.addSubview(button)
        textField.becomeFirstResponder()
    }

    @objc func didClickedButton() {
        navigationController?.popViewController(animated: true)
        callBack?(textField.text)
    }
}

class URLServiceRouterDelegate: URLServiceRouterDelegateProtocol {
    func currentViewController() -> UIViewController? {
        var topViewController = UIApplication.shared.delegate?.window??.rootViewController
        while let viewController = topViewController?.presentedViewController {
            topViewController = viewController
        }
        while let viewController = topViewController,
              viewController is UINavigationController,
              let navigationController = viewController as? UINavigationController,
              let topVC = navigationController.topViewController
        {
            topViewController = topVC
        }
        return topViewController
    }

    func currentNavigationController() -> UINavigationController? {
        return currentViewController()?.navigationController
    }

    func shouldRoute(request: URLServiceRequestProtocol) -> Bool {
        return true
    }

    func dynamicProcessingServiceRequest(_ request: URLServiceRequestProtocol) {}

    func logError(_ message: String) {
        print("❌URLServiceRouter log error start: \n\(message)\nURLServiceRouter log error end❌")
    }

    func logInfo(_ message: String) {
        print("‼️ URLServiceRouter log info start: \n\(message)\nURLServiceRouter log info end‼️")
    }
}

struct URLServiceRedirectTestHostParser: URLServiceNodeParserProtocol {
    let priority: Int = URLServiceNodeParserPriorityDefault
    var parserType: URLServiceNodeParserType = .pre

    func parse(request: URLServiceRequestProtocol, decision: URLServiceNodeParserDecisionProtocol) {
        if let host = request.url.host, request.nodeNames.contains(host), host.isTestHost {
            var nodeNames = request.nodeNames
            nodeNames.remove(at: 0)
            nodeNames.insert(String.productionHost, at: 0)
            request.replace(nodeNames: nodeNames, from: self)
        }
        decision.next()
    }
}

extension String {
    var isTestHost: Bool {
        return hasSuffix(".realword.io")
    }

    static var productionHost: String {
        return "www.realword.com"
    }

    var isPureInt: Bool {
        let scanner = Scanner(string: self)
        var value: UnsafeMutablePointer<Int>?
        return scanner.scanInt(value) && scanner.isAtEnd
    }
}

public struct URLServiceRedirectHttpParser: URLServiceNodeParserProtocol {
    public let priority: Int = URLServiceNodeParserPriorityDefault
    public var parserType: URLServiceNodeParserType = .pre

    public func parse(request: URLServiceRequestProtocol, decision: URLServiceNodeParserDecisionProtocol) {
        if let scheme = request.url.scheme, scheme == "http", request.nodeNames.contains(scheme) {
            var nodeNames = request.nodeNames
            nodeNames.remove(at: 0)
            nodeNames.insert("https", at: 0)
            request.replace(nodeNames: nodeNames, from: self)
        }
        decision.next()
    }
}
