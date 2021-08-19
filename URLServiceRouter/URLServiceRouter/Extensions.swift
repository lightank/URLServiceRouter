//
//  Extensions.swift
//  URLServiceRouter
//
//  Created by huanyu.li on 2021/7/31.
//  Copyright © 2021 huanyu.li. All rights reserved.https://github.com/lightank/URLServiceRouter
//

import Foundation

extension RandomAccessCollection {
    public func binarySearch(predicate: (Iterator.Element) -> Bool) -> Index {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = index(low, offsetBy: distance(from: low, to: high)/2)
            if predicate(self[mid]) {
                low = index(after: mid)
            } else {
                high = mid
            }
        }
        return low
    }
}

extension URL {
    public var nodeQueryItems: [String: String] {
        var params = [String: String]()
        return URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .reduce([:], { (_, item) -> [String: String] in
                params[item.name] = item.value
                return params
            }) ?? [:]
    }
    
    public var nodeNames: [String] {
        var nodeNames = [String]()
        
        if let scheme = scheme?.lowercased() {
            nodeNames.append(scheme)
        }
        if let host = host?.lowercased() {
            nodeNames.append(host)
        }
        
        var paths = pathComponents
        if paths.count > 0 && paths.first == "/" {
            paths.remove(at: 0)
        }
        if !path.isEmpty {
            nodeNames += paths.map{ $0.lowercased()}
        }
        
        return nodeNames;
    }
    
    public var nodeUrl: URL {
        var nodeUrl = ""
        if let scheme = scheme?.lowercased() {
            nodeUrl += "\(scheme)://"
        }
        
        var paths = pathComponents
        if paths.count > 0 && paths.first == "/" {
            paths.remove(at: 0)
        }
        if let host = host?.lowercased() {
            paths.insert(host, at: 0)
        }
        nodeUrl += paths.map{ $0.lowercased()}.joined(separator: "/")
        if let url = URL(string: nodeUrl) {
            return url
        } else {
            assert(true, "this url：\(absoluteURL)")
            return self
        }
    }
}
