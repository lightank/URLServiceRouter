# URLServiceRouter

[![Cocoapods](https://img.shields.io/cocoapods/v/URLServiceRouter.svg)](https://cocoapods.org/pods/URLServiceRouter)
[![Carthage compatible](https://img.shields.io/badge/Carthage-Compatible-brightgreen.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SPM compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager/)
[![Swift](https://img.shields.io/badge/Swift-5.3-orange.svg)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-12.4-blue.svg)](https://developer.apple.com/xcode)

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
URLServiceRouter.shared.registerService(name: "user://info") {
    URLOwnerInfoService()
}
```

注册将测试环境host转为生产环境host的解析器

```swift
URLServiceRouter.shared.registerNode(from: "https") {
    [URLServiceRedirectTestHostParser()]
}
```

注册 owner URL 到 nodeTree 中

```swift
do {
    URLServiceRouter.shared.registerNode(from: "https://www.realword.com/owner/info") {
        [URLServiceNoramlParser(parserType: .post, parseBlock: { nodeParser, _, decision in
            decision.complete(nodeParser, "user://info")
        })]
    }
}

do {
    URLServiceRouter.shared.registerNode(from: "https://www.realword.com/owner/") {
        let preParser = URLServiceNoramlParser(parserType: .pre, parseBlock: { nodeParser, request, decision in
            var nodeNames = request.nodeNames
            if let first = nodeNames.first, first.isPureInt {
                request.merge(params: ["id": nodeNames.remove(at: 0)], from: nodeParser)
                request.replace(nodeNames: nodeNames, from: nodeParser)
            }
            decision.next()
        })
        
        let postParser = URLServiceNoramlParser(parserType: .post, parseBlock: { _, _, decision in
            decision.next()
        })
        return [preParser, postParser]
    }
}
```

请求 owner 服务

```swift
if let url = URL(string: "http://china.realword.io/owner/1/info") {
    URLServiceRequest(url: url).start(callback: { request in
        if let data = request.response?.data {
            // 正确的数据
            self.showAlertMessge(title: "回调的业务数据", message: String(describing: data))
        }
        URLServiceRouter.shared.logInfo("\(String(describing: request.response?.data))")
    })
}
```

直接调用服务

```swift
URLServiceRouter.shared.callService(name: "user://info", params: "1") { _, _ in
} callback: { result, _ in
    self.showAlertMessge(title: "回调的业务数据", message: String(describing: result))
    URLServiceRouter.shared.logInfo("\(String(describing: result))")
}
```