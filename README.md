# URLServiceRouter

[![Cocoapods](https://img.shields.io/cocoapods/v/URLServiceRouter.svg)](https://cocoapods.org/pods/URLServiceRouter)
[![Carthage compatible](https://img.shields.io/badge/Carthage-Compatible-brightgreen.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SPM compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager/)
[![Swift](https://img.shields.io/badge/Swift-5.3-orange.svg)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-12.4-blue.svg)](https://developer.apple.com/xcode)

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

register deeplink

```swift
do {
    let parser = URLServiceNoramlParser(parserType: .post, parseBlock: { (nodeParser, request, currentNode, decision) in
        decision.complete("user://info")
    })
     
    URLServiceRouter.share.registerNode(from: "https://www.realword.com/owner/info", parsers:[parser]);
}

do {
    let parser = URLServiceNoramlParser(parserType: .pre, parseBlock: { (nodeParser, request, currentNode, decision) in
        var nodeNames = request.nodeNames
        if let first = nodeNames.first, first.isPureInt {
            request.merge(params: ["id": nodeNames.remove(at: 0)], from: nodeParser)
            request.replace(nodeNames: nodeNames, from: nodeParser)
        }
        decision.next()
    })
     
    URLServiceRouter.share.registerNode(from: "https://www.realword.com/owner/", parsers:[parser]);
}
```

request service

```swift
if let url = URL(string: "http://china.realword.io/owner/1/info") {
    URLServiceRequest(url: url).start(callback: { (request) in
         if let data = request.response?.data {

        }
        URLServiceRouter.share.logInfo("\(String(describing: request.response?.data))")
    })
}
```

call service

```swift
URLServiceRouter.share.callService(name: "user://info", params: "1") { (service, error) in
            
} callback: { (result) in
            
}
```