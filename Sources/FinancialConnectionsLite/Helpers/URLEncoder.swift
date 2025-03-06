//
//  URLEncoder.swift
//  FinancialConnectionsLite
//
//  Created by Mat Schmid on 2025-02-20.
//

import Foundation

enum URLEncoder {
    static func queryString(from parameters: [String: Any]) -> String {
        let flattenedParams = flattenParameters(parameters)
        let pairs = flattenedParams.map { key, value in
            let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "\(value)"
            return "\(escapedKey)=\(escapedValue)"
        }
        return pairs.joined(separator: "&")
    }
    
    static func flattenParameters(_ parameters: [String: Any], prefix: String = "") -> [String: Any] {
        var flattenedParams: [String: Any] = [:]
        
        for (key, value) in parameters {
            let keyPath = prefix.isEmpty ? key : "\(prefix)[\(key)]"
            
            if let dict = value as? [String: Any] {
                // Recursively flatten nested dictionaries
                let nestedParams = flattenParameters(dict, prefix: keyPath)
                flattenedParams.merge(nestedParams) { (_, new) in new }
            } else if let array = value as? [Any] {
                // Handle arrays by using indexed notation
                for (index, item) in array.enumerated() {
                    let arrayKeyPath = "\(keyPath)[\(index)]"
                    
                    if let nestedDict = item as? [String: Any] {
                        let nestedParams = flattenParameters(nestedDict, prefix: arrayKeyPath)
                        flattenedParams.merge(nestedParams) { (_, new) in new }
                    } else {
                        flattenedParams[arrayKeyPath] = stringFromValue(item)
                    }
                }
            } else {
                // Store regular parameter
                flattenedParams[keyPath] = stringFromValue(value)
            }
        }
        
        return flattenedParams
    }
    
    private static func stringFromValue(_ value: Any) -> String {
        switch value {
        case let bool as Bool:
            return bool ? "true" : "false"
        case let number as NSNumber:
            return number.stringValue
        case let url as URL:
            return url.absoluteString
        default:
            return "\(value)"
        }
    }
}
