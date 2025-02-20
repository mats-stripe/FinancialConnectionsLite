//
//  URLEncoder.swift
//  FinancialConnectionsLite
//
//  Created by Mat Schmid on 2025-02-20.
//

import Foundation

enum URLEncoder {
    static func queryString(from parameters: [String: Any]) -> String {
        let pairs = parameters.map { key, value in
            let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "\(value)"
            return "\(escapedKey)=\(escapedValue)"
        }
        return pairs.joined(separator: "&")
    }
}
