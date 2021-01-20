# LTURLRounter

这是一套用于解析URL，并执行相应操作的解析协议，以及一个具体的实现。主要的实现方式是取其精华：提取 URL pathComponent 中有意义的模块进行注册，自动忽略无模块意义的 pathComponent。

## 解决的问题
1. URL 中有效 pathComponent 是不连续的，可能位置还不固定，我们需要找出其中有意义的模块
2. URL 中无效的 pathComponent 需要忽略，比如语言、SEO

## 总体设计

1. 对 iOS 内部解析来说，无论是哪一种跳转，对象都是 NSURL，所以重点是如何对 NSRUL 的解析
2. URL 的构造
    - scheme
    - host
    - pathComponents（包含很多个pathComponent）
    - 参数：queryItems
3. 解析 URL 具体模块需要把scheme、host、参数排除在外，参数用于处理过程，不用于模块区分，那么将会是这样的：`pathComponent -> pathComponent -> pathComponent -> ...`
    - 对于 `scheme` 与 `host` 需要外部过滤，内部只处理 `pathComponent`
    - 以上每个有意义、是业务模块的 `pathComponent`需注册为模块，非模块无需注册
    - 取消根模块，所有模块以`pathComponent`数组链的形式注册到一个数组中
    - 例子：`https://www.klook.com/zh-CN/hotel/2222/detail` 包含2个模块：`hotel`、`detail`
        - `hotel` 模块添加在模块数组下
        - `detail` 注册在 `hotel` 模块下
        - 假定 `https://www.klook.com/zh-CN/hotel/2222/detail`  中 `hotel`后面的 id 是酒店 id，这个时候 id 不是模块，那么无需注册，仍然只需注册上述2个模块，在解析的时候，按照模块顺序去查找，没有注册的模块会自动跳过，最终会交给 `detail` 模块处理
    - 如果链接中出现了非注册模块路径，比如 `zh-CN` ，在遍历 URL  `pathComponent` 时会自动过滤掉
    - 我们只需对对模块进行封装，添加注册方法就可以实现模块嵌套，我们称之为模块链
        - 按模块来处理，也方便后续各模块独立开发