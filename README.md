# LTURLRounter

这是一套用于解析URL，并执行相应操作的解析协议，以及一个具体的实现。主要的实现方式是取其精华：提取 `URL` `pathComponents` 中有意义的模块进行注册，自动忽略无模块意义的 `pathComponent`，。

## 解决的问题

1. URL 中有效 `pathComponent` 是不连续的，可能位置还不固定，我们需要找出其中有意义的模块
2. URL 中无效的 `pathComponent` 需要忽略，比如语言、SEO

## 流程协议化

侧重于流程，也就是说要抽象为协议，具体实现由各业务线自己决定，主要包含内容如下

1. `URL` 模块，包含的内容如下：
    1. 模块名字、处理
    2. 注册子模块
    3. 当前模块：能否处理`URL`、处理`URL`
    4. 模块链：能否能否处理`URL`、处理`URL`
    5. 实现如下：

    ```swift
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
    ```

2. `URL` 解析中心，负责查找解析，包含的内容如下：
    1. 子模块数组（不提供注册方法是为了让实现方更灵活去注册，比如：链式注册、扁平式注册等）
    2. 找到最佳处理`URL`的模块
    3. 处理这个模块
    4. 实现如下：

    ```swift
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
    ```

3. 如果公司各业务需要一个统一的处理，那整个app只要维护一个解析中心。如果对于解析过程各业务线不一样，那么这个解析中心应该代表某一个具体的业务线，整个app维护的是一个解析中心数组。ps：可以用一个类同时实现两个协议，这个时候模块就会同时承担解析与处理。

## 一个有回溯的具体实现

根据上面的协议

1. 对 iOS 内部解析来说，无论是哪一种跳转，对象都是 NSURL，所以重点是如何对 NSRUL 的解析
2. `URL` 的构造
    - `scheme`
    - `host`
    - `pathComponents`（包含很多个`pathComponent`）
    - 参数：`queryItems`
3. 注册模块，核心内容：取其精华，只提取有效数据：
    - 解析 URL 具体模块需要把`scheme`、`host`、参数排除在外，参数用于处理过程，不用于模块区分那么将会是这样的：`pathComponent -> pathComponent -> pathComponent -> ...`，而我们需要取其精华，即只提取对我们有意义的`pathComponent`注册为模块，忽略掉无效的，即使`pathComponent`是非连续的
    - 对于 `scheme` 与 `host` 需要外部过滤，内部只处理 `pathComponent`
    - 每个有意义、是业务模块的 `pathComponent`需注册为模块，非模块无需注册
    - 取消根模块，所有模块以`pathComponent`数组链的形式注册到一个路由中心中
    - 我们只需对对模块进行封装，添加注册方法就可以实现模块嵌套，我们称之为模块链
    - 通过模块的注册在解析前，我们应该可以得到一棵模块树
4. 解析过程
    1. 得到`URL`的`pathComponents`数组，遍历这个数组，
    2. 如果链接中出现了非注册模块路径，比如 `zh-CN` ，在遍历 URL `pathComponent` 时会自动忽略掉
    3. 例子：`https://www.klook.com/zh-CN/hotel/2222/detail` 包含2个模块：`hotel`、`detail`，跟在 `hotel`后面的 id 是酒店 id，这个url主要是要打开指定id的酒店详情页
        - 先注册这两个 `hotel` 模块添加在路由中心模块字典下，`detail` 注册在 `hotel` 模块下
        - `pathComponents`为：`zh-CN`、`hotel`、`2222`、`detail`，我们遍历这个字符串数组，初始情况下最合适的模块是个`nil`，这个时候去路由中心模块字典下找对应的模块，如果最合适的模块有值，应该是从它的子模块里去查找。没有注册的`pathComponent`会由于找不到模块将自动用下一个`pathComponent`去查找。
            - 我们用`×` 表示没有命中，`√`表示命中，最终结果：`zh-CN`：`×`、`hotel`：`√`、`2222`：`×`、`detail`：`√`，找到的模块是：`detail`
        - 代码如下：

        ```
        @objc public func bestModuleFor(url: URL) -> URLModuleProtocol? {
            if (url.absoluteString.count == 0 || url.pathComponents.count == 0) {
                return nil
            }
            
            let pathComponents = url.pathComponents
            var bestModule: URLModuleProtocol? = nil
            pathComponents.forEach { (pathComponent) in
                var subModule: URLModuleProtocol? = nil
                if (bestModule == nil) {
                    if subModules[pathComponent] != nil {
                        subModule = subModules[pathComponent]
                    }
                } else {
                    if bestModule!.subModules[pathComponent] != nil {
                        subModule = bestModule!.subModules[pathComponent]
                    }
                }
                
                if (subModule != nil) {
                    bestModule = subModule
                }
            }
            
            return bestModule;
        }
        ```

    以上，是本人根据自己的理解，对协议的一套具体实现，不同业务线也可以根据自身需要自己去定义。

    比如在找到业务线模块时先判断这个大业务线是否能够处理，如果不能，解析将不往下走：

    ```
    @objc public func bestModuleFor(url: URL) -> URLModuleProtocol? {
        if (url.absoluteString.count == 0 || url.pathComponents.count == 0) {
            return nil
        }
        
        let pathComponents = url.pathComponents
        var bestModule: URLModuleProtocol? = nil
        pathComponents.forEach { (pathComponent) in
            var subModule: URLModuleProtocol? = nil
            if (bestModule == nil) {
                if subModules[pathComponent] != nil {
                    subModule = subModules[pathComponent]
                }
            } else {
                if bestModule!.subModules[pathComponent] != nil {
                    subModule = bestModule!.subModules[pathComponent]
                }
            }
            
    				// 这里进行判断找到的模块能否处理
            if (subModule != nil && subModule!.canHandleURLBlock(url)) {
                bestModule = subModule
            }
        }
        
        return bestModule;
    }
    ```

    以上流程整个流程注册与处理流程如下

    ```swift
    let hotel: URLModule = URLModule.init(name: "hotel", parentModule: nil)
        
    let detail: URLModule = URLModule.init(name: "detail", parentModule: hotel)
    detail.canHandleURLBlock = {_ in true}
    detail.handleURLBlock = {(url: URL) in
        print("跳转到酒店详情页")
    }
    hotel.registe(subModule: detail)

    let url: URL = URL.init(string: "https://www.klook.com/hotel/1234/detail")!
    URLRounter.sharedInstance.registe(subModule: hotel)
    let bestModule = URLRounter.sharedInstance.bestModuleFor(url: url)
    bestModule?.handleURLBlock(url)
    ```

    ## 一个扁平化的具体实现

    我不想注册不断的去注册子模块，能不能给个字符串数组，命中模块就处理，不命中就不处理啊？

    也是可以的，其它逻辑与上面的一样，只需要修改一下注册方式就行，

    ```
    @objc public func registeModules(pathComponents: [String], handleURLBlock: @escaping (_ url: URL) -> Void) {
        if (pathComponents.count == 0) {
            return;
        }
        
        var currentModule: URLModuleProtocol? = nil
        pathComponents.forEach { (pathComponent) in
            assert(pathComponent.count > 0, "注册的模块名字不能为空,请检测")
            var subModule: URLModuleProtocol? = nil
            if currentModule == nil {
                subModule = subModules[pathComponent]
                if subModule == nil {
                    subModule = URLModule.init(name: pathComponent, parentModule: nil)
                    registe(subModule: subModule!)
                }
            } else {
                subModule = currentModule!.subModules[pathComponent]
                if subModule == nil {
                    subModule = URLModule.init(name: pathComponent, parentModule: currentModule)
                    currentModule?.registe(subModule: subModule!)
                }
            }
            currentModule = subModule
            
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
    ```

    以上流程整个流程注册与处理流程如下：

    ```
    URLFlatRounter.sharedInstance.registeModules(pathComponents: ["hotel", "detail"]) { (url) in
        print("跳转到酒店详情页")
    }

    URLFlatRounter.sharedInstance.registeModules(pathComponents: ["hotel"]) { (url) in
        print("跳转到酒店垂直页")
    }

    URLFlatRounter.sharedInstance.handle(url: URL.init(string: "https://www.klook.com/hotel/1234/detail")!)
    URLFlatRounter.sharedInstance.handle(url: URL.init(string: "https://www.klook.com/hotel/1234/detail1")!)
    ```