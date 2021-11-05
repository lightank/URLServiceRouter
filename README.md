# URLServiceRouter

[![Cocoapods](https://img.shields.io/cocoapods/v/URLServiceRouter.svg)](https://cocoapods.org/pods/URLServiceRouter)
[![Carthage compatible](https://img.shields.io/badge/Carthage-Compatible-brightgreen.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SPM compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager/)
[![Swift](https://img.shields.io/badge/Swift-5.3-orange.svg)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-12.4-blue.svg)](https://developer.apple.com/xcode)

中文版本
==================


## 这是什么？

URLServiceRouter 是一个基于 URL 用 Swift 写的一个路由分发库，由一个高自由度的 nodeTree 跟 RPC 来实现的。

## 安装

### CocoaPods

1. 在 Podfile 中添加 `pod 'URLServiceRouter'`.
2. 执行 `pod install` 或 `pod update`.
3. 使用时，导入文件：`import URLServiceRouter`

### Carthage

1. 在 Cartfile 文件中添加 `github "lightank/URLServiceRouter"`.
2. 执行 `carthage update --platform ios` 并把 framework 添加到你的 Target 中.
3. 使用时，导入文件：`import URLServiceRouter`

### SPM

1. 在添加 Swift Package 时，输入 `https://github.com/lightank/URLServiceRouter.git`
2. 选择最新的tag.
3. 使用时，导入文件：`import URLServiceRouter`

## 要求

* iOS 10.0
* Swift 5.x
* Xcode 12.x

## 开始使用

我们假设

- 在一个真实世界的服务器中, 产线环境是：`www.realword.com`, 测试环境是：`*.realword.io`
- `http://china.realword.io/owner/<owner_id>/info` 代表查询 `owner_id` 对应的用户信息

注册 owner 服务

```swift
URLServiceRouter.share.register(service: URLOwnerInfoService())
```

注册将测试环境host转为生产环境host的解析器

```swift
URLServiceRouter.shared.registerNode(from: "https", parsers:[URLServiceRedirectTestHostParser()])
```

注册 owner URL 到 nodeTree 中

```swift
do {
    let parser = URLServiceNoramlParser(parserType: .post, parseBlock: { (nodeParser, request, decision) in
        decision.complete(nodeParser ,"user://info")
    })
     
    URLServiceRouter.shared.registerNode(from: "https://www.realword.com/owner/info", parsers: [parser]);
}

do {
    let preParser = URLServiceNoramlParser(parserType: .pre, parseBlock: { (nodeParser, request, decision) in
        var nodeNames = request.nodeNames
        if let first = nodeNames.first, first.isPureInt {
            request.merge(params: ["id": nodeNames.remove(at: 0)], from: nodeParser)
            request.replace(nodeNames: nodeNames, from: nodeParser)
        }
        decision.next()
    })
    
    let postParser = URLServiceNoramlParser(parserType: .post, parseBlock: { (nodeParser, request, decision) in
        decision.next()
    })
     
    URLServiceRouter.shared.registerNode(from: "https://www.realword.com/owner/", parsers:[preParser, postParser]);
}
```

请求 owner 服务

```swift
if let url = URL(string: "http://china.realword.io/owner/1/info") {
    URLServiceRequest(url: url).start(callback: { (request) in
        if let data = request.response?.data {
            // 正确的数据
            self.showAlertMessge(title: "回调的业务数据", message: String(describing: data) )
        }
        URLServiceRouter.shared.logInfo("\(String(describing: request.response?.data))")
    })
}
```

直接调用服务

```swift
URLServiceRouter.shared.callService(name: "user://info", params: "1") { (service, error) in
    
} callback: { (result, error) in
    self.showAlertMessge(title: "回调的业务数据", message: String(describing: result) )
    URLServiceRouter.shared.logInfo("\(String(describing: result))")
}
```


English Version
==================

## What is it?

URLServiceRouter is a Swift URL router implemented by a high-degree-of-freedom nodeTree and RPC.

## Installation

### CocoaPods

1. Add `pod 'URLServiceRouter'` to your Podfile.
2. Run `pod install` or `pod update`.
3. `import URLServiceRouter`

### Carthage

1. Add `github "lightank/URLServiceRouter"` to your Cartfile.
2. Run `carthage update --platform ios` and add the framework to your project.
3. `import URLServiceRouter`

### SPM

1. input `https://github.com/lightank/URLServiceRouter.git` when adding Swift Package
2. choose the newest tag
3. `import URLServiceRouter`


## Requirements

* iOS 10.0
* Swift 5.x
* Xcode 12.x

## Getting Started

Assumptions:

- In a real-world server, the official server is: `www.realword.com`, and the test server is: `*.realword.io`
- `http://china.realword.io/owner/<owner_id>/info` represents the identity information of `owner_id`

register service:

```swift
URLServiceRouter.share.register(service: URLOwnerInfoService())
```

register node parser for changing host from test server to official server

```swift
URLServiceRouter.shared.registerNode(from: "https", parsers:[URLServiceRedirectTestHostParser()])
```

register deeplink

```swift
do {
    let parser = URLServiceNoramlParser(parserType: .post, parseBlock: { (nodeParser, request, decision) in
        decision.complete(nodeParser ,"user://info")
    })
     
    URLServiceRouter.shared.registerNode(from: "https://www.realword.com/owner/info", parsers: [parser]);
}

do {
    let preParser = URLServiceNoramlParser(parserType: .pre, parseBlock: { (nodeParser, request, decision) in
        var nodeNames = request.nodeNames
        if let first = nodeNames.first, first.isPureInt {
            request.merge(params: ["id": nodeNames.remove(at: 0)], from: nodeParser)
            request.replace(nodeNames: nodeNames, from: nodeParser)
        }
        decision.next()
    })
    
    let postParser = URLServiceNoramlParser(parserType: .post, parseBlock: { (nodeParser, request, decision) in
        decision.next()
    })
     
    URLServiceRouter.shared.registerNode(from: "https://www.realword.com/owner/", parsers:[preParser, postParser]);
}
```

request service

```swift
if let url = URL(string: "http://china.realword.io/owner/1/info") {
    URLServiceRequest(url: url).start(callback: { (request) in
        if let data = request.response?.data {
            // real data
            
        }
        URLServiceRouter.shared.logInfo("\(String(describing: request.response?.data))")
    })
}
```

call service

```swift
URLServiceRouter.shared.callService(name: "user://info", params: "1") { (service, error) in
    
} callback: { (result, error) in
    URLServiceRouter.shared.logInfo("\(String(describing: result))")
}
```