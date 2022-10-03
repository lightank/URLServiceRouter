//
//  Extensions.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/7/31.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
//

import Foundation

public extension Array where Element == String {
    /// 将数组中的字符串用 / 连接起来
    var nodeUrlKey: String {
        return joined(separator: URLComponentSeparator)
    }
}

public extension RandomAccessCollection {
    /// 二分法查找符合谓词的最佳插入index
    /// - Parameter predicate: 谓词
    /// - Returns: 最佳index
    func binarySearch(predicate: (Iterator.Element) -> Bool) -> Index {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = index(low, offsetBy: distance(from: low, to: high) / 2)
            if predicate(self[mid]) {
                low = index(after: mid)
            } else {
                high = mid
            }
        }
        return low
    }
}

public let URLComponentSeparator = "/"

public extension URL {
    /// 将 URL 的 Components 转为 key、value 均为 String 的字典
    var nodeQueryItems: [String: String] {
        var params = [String: String]()
        return URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .reduce([:]) { _, item -> [String: String] in
                params[item.name] = item.value
                return params
            } ?? [:]
    }

    /// 将 URL 的 scheme、host、pathComponents 中的元素按左到右的顺序添加到一个字符串数组中，其中 scheme、host 会统一转为小写
    var nodeNames: [String] {
        var nodeNames = [String]()

        if let scheme = scheme?.lowercased() {
            nodeNames.append(scheme)
        }
        if let host = host?.lowercased() {
            nodeNames.append(host)
        }

        var paths = pathComponents
        if paths.first == URLComponentSeparator {
            paths.remove(at: 0)
        }
        if !path.isEmpty {
            nodeNames += paths
        }

        return nodeNames
    }

    /// 将 URL 的 scheme、host 转为小写
    var nodeUrl: URL {
        var nodeUrl = ""
        if let scheme = scheme?.lowercased() {
            nodeUrl += "\(scheme)://"
        }

        var paths = pathComponents
        if paths.first == URLComponentSeparator {
            paths.remove(at: 0)
        }
        if let host = host?.lowercased() {
            paths.insert(host, at: 0)
        }
        nodeUrl += paths.joined(separator: URLComponentSeparator)
        if let url = URL(string: nodeUrl) {
            return url
        } else {
            URLServiceRouter.shared.logError("this url：\(self) can not turn to node url")
            assert(true, "this url：\(absoluteURL) can not turn to node url")
            return self
        }
    }
}

public extension String {
    var nodeUrl: String {
        if let url = URL(string: self) {
            return url.nodeUrl.absoluteString
        } else {
            URLServiceRouter.shared.logError("this string：\(self) can not turn to node url")
            assert(true, "this string：\(self) can not turn to node url")
            return self
        }
    }
}
