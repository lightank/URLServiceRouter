//
//  Extensions.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/7/31.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
//

import Foundation

public extension Array where Element == String {
    var nodeUrlKey: String {
        return joined(separator: URLComponentSeparator)
    }
}

public extension RandomAccessCollection {
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
    var nodeQueryItems: [String: String] {
        var params = [String: String]()
        return URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .reduce([:], { (_, item) -> [String: String] in
                params[item.name] = item.value
                return params
            }) ?? [:]
    }
    
    var nodeNames: [String] {
        var nodeNames = [String]()
        
        if let scheme = scheme?.lowercased() {
            nodeNames.append(scheme)
        }
        if let host = host?.lowercased() {
            nodeNames.append(host)
        }
        
        var paths = pathComponents
        if paths.count > 0 && paths.first == URLComponentSeparator {
            paths.remove(at: 0)
        }
        if !path.isEmpty {
            nodeNames += paths
        }
        
        return nodeNames;
    }
    
    var nodeUrl: URL {
        var nodeUrl = ""
        if let scheme = scheme?.lowercased() {
            nodeUrl += "\(scheme)://"
        }
        
        var paths = pathComponents
        if paths.count > 0 && paths.first == URLComponentSeparator {
            paths.remove(at: 0)
        }
        if let host = host?.lowercased() {
            paths.insert(host, at: 0)
        }
        nodeUrl += paths.joined(separator: URLComponentSeparator)
        if let url = URL(string: nodeUrl) {
            return url
        } else {
            assert(true, "this url：\(absoluteURL)")
            return self
        }
    }
}

public extension String {
    var nodeUrl: String {
        if let url = URL(string: self) {
            return url.nodeUrl.absoluteString
        } else {
            return self
        }
    }
}
