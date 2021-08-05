# URLServiceRouter

移动端的代码随着义务、技术栈的发展，逐渐演变成跨APP、组件、技术栈（比如：flutter）等的庞大工程，各业务线各类服务怎么交互变成一个大问题，需要找到他们的共同点才能解决这个问题。


## 开发者想要的

1. 如果把不同组件当成单独的服务器，那么通过 rpc 调用，将整个过程封装成一个请求，提供url、参数来调用服务并返回我想要的结果（如果有的话），这么看的话，跟普通http请求类似了，我们将这个过程称之为：服务调用
2. 要想做到rpc调用，就得抹平各组件的差异性，封装成一个对象，我们称之为：服务
3. 服务可以一对多个外部链接，同时支持回调
4. 服务需要注册到一个管理器中，我们称之为：服务路由器，它提供服务调用的nodeTree，同时提供服务注册功能
5. 外部调用（https、scheme）只能通过服务路由器来查找对应的内部服务并调用，内部服务的调用过程跟外部调用完全不同，可以更灵活的实现，比如：支持对象

总得来讲：API简单易用，但需要一定的自由度来支撑多变的业务

## 我的方案：高自由度的nodeTree + RPC

url 路径解析方案大同小异，最终都会构建一个 nodetree，用于路径查找。但路径查找完后就直接调用了？貌似不太好，这个决定应该交给开发者，而且要给予很大的自由空间：

1. 做出的决定可以改变请求的部分信息，比如：请求参数、后续路径信息
2. 既能在路径查找过程中做出决定
3. 也能在路径回溯的过程中做出决定
4. 在这个决定中可能给出最终要调用的服务名，最后由服务路由器去调用具体服务

解决了nodeTree的问题，接下来解决RPC的问题：

1. 单次服务调用封装成一个请求对象，并由它来告知开发者请求的结果跟服务回调

上述整个过程应该抽象成一个协议，开发者可以自由实现，以满足不同业务需求。

## 如何使用

假设：

- 一个真实世界服务器里，正式服务器是：`www.realword.com`，测试服务器是：`*.realword.io`
- `http://china.realword.io/owner/<owner_id>/info`代表要取`owner_id`的身份信息

注册服务

```swift
URLServiceRouter.share.register(service: URLOwnerInfoService())
```

注册deeplink

```swift
URLServiceRouter.share.registerNode(from: "https://www.realword.com/owner/") { (node) in
	// 注册前序解析器，拿掉后面的id
	node.registe(parser: URLServiceNoramlParser(parserType: .pre, parseBlock: { (nodeParser, request, currentNode, decision) in
		var nodeNames = request.nodeNames
		if let first = nodeNames.first, first.isPureInt {
			request.merge(params: ["id": nodeNames.remove(at: 0)], from: nodeParser)
			request.replace(nodeNames: nodeNames, from: nodeParser)
		}
		decision.next()
	}))
}
        
URLServiceRouter.share.registerNode(from: "https://www.realword.com/owner/info") { (node) in
	// 注册后序解析器，返回想要执行的服务名称
	node.registe(parser: URLServiceNoramlParser(parserType: .pre, parseBlock: { (nodeParser, request, currentNode, decision) in
		decision.complete("user://info")
	}))
}
```

服务调用

```swift
if let url = URL(string: "http://china.realword.io/owner/1/info") {
	URLServiceRequest(url: url).start { (request) in
                
	} failure: { (request) in
                
	} serviceCallback: { (result) in
		URLServiceRouter.share.logInfo("\(String(describing: result))")
	}
}
```

如果要内部服务调用

```swift
// 这里的 params 是支持直接传对象的，能否处理主要看service的实现
URLServiceRouter.share.callService(name: "user://info", params: "1") { (service, error) in
            
} callback: { (result) in
            
}
```