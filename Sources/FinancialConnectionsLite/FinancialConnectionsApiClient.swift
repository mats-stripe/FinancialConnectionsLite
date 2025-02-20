//
//  FinancialConnectionsApiClient.swift
//  FinancialConnectionsLite
//
//  Created by Mat Schmid on 2025-02-20.
//

import Foundation

struct FinancialConnectionsApiClient {
    static let shared = FinancialConnectionsApiClient()
    static var publishableKey: String!

    private static let decoder = JSONDecoder()

    private enum Endpoint {
        private static let baseApiUrl: URL = URL(string: "https://api.stripe.com/v1")!

        case generateHostedUrl

        var path: String {
            switch self {
            case .generateHostedUrl: "link_account_sessions/generate_hosted_url"
            }
        }

        var url: URL {
            Endpoint.baseApiUrl.appendingPathComponent(path)
        }
    }

    private init() {}

    /// Generates a hosted auth url for a `LinkAccountSession`.
    static func generateHostedUrl(
        clientSecret: String,
        returnUrl: URL
    ) async throws -> LinkAccountSessionManifest {
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "app_return_url": returnUrl.absoluteString,
            "fullscreen": true,
            "hide_close_button": true,
        ]
        
        return try await post(endpoint: .generateHostedUrl, parameters: parameters)
    }
    
    private static func post<T: Decodable>(
        endpoint: Endpoint,
        parameters: [String: Any]
    ) async throws -> T {
        var request = URLRequest(url: Endpoint.generateHostedUrl.url)
        let formData = URLEncoder.queryString(from: parameters).data(using: .utf8)
        request.httpBody = formData
        request.httpMethod = "POST"
        request.setValue(
            "Bearer \(publishableKey)",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue(
            String(format: "%lu", UInt(formData?.count ?? 0)),
            forHTTPHeaderField: "Content-Length"
        )
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )

        let (data, _) = try await URLSession.shared.data(for: request)
        return try decoder.decode(T.self, from: data)
    }
}
