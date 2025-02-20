//
//  URLEncoderTests.swift
//  FinancialConnectionsLite
//
//  Created by Mat Schmid on 2025-02-20.
//

import XCTest
@testable import FinancialConnectionsLite

class URLEncoderTests: XCTestCase {
    func testQueryString() {
        let parameters: [String: Any] = [
            "name": "John Doe",
            "age": 30,
            "email": "john@example.com"
        ]
        
        let result = URLEncoder.queryString(from: parameters)
        let expected = "age=30&email=john@example.com&name=John%20Doe"
        XCTAssertEqual(result, expected)
    }
}
