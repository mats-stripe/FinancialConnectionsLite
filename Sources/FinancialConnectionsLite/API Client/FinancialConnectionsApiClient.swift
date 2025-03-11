//
//  FinancialConnectionsApiClient.swift
//  FinancialConnectionsLite
//
//  Created by Mat Schmid on 2025-02-20.
//

import Foundation

struct FinancialConnectionsApiClient {
    private static let decoder = JSONDecoder()

    private let publishableKey: String

    private enum Endpoint {
        private static let baseApiUrl: URL = URL(string: "https://api.stripe.com/v1")!

        case synchronize
        case sessionReceipt
        case listAccounts

        var path: String {
            switch self {
            case .synchronize: "financial_connections/sessions/synchronize"
            case .sessionReceipt: "link_account_sessions/session_receipt"
            case .listAccounts: "link_account_sessions/list_accounts"
            }
        }

        var url: URL {
            Endpoint.baseApiUrl.appendingPathComponent(path)
        }
    }
    
    private enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }

    init(publishableKey: String) {
        self.publishableKey = publishableKey
    }

    private func get<T: Decodable>(
        endpoint: Endpoint,
        parameters: [String: Any]
    ) async throws -> T {
        try await request(endpoint: endpoint, parameters: parameters, method: .get)
    }

    private func post<T: Decodable>(
        endpoint: Endpoint,
        parameters: [String: Any]
    ) async throws -> T {
        try await request(endpoint: endpoint, parameters: parameters, method: .post)
    }
    
    private func request<T: Decodable>(
        endpoint: Endpoint,
        parameters: [String: Any],
        method: HTTPMethod
    ) async throws -> T {
        var request: URLRequest

        switch method {
        case .get:
            // For GET requests: append parameters to URL
            guard var components = URLComponents(url: endpoint.url, resolvingAgainstBaseURL: true) else {
                throw URLError(.badURL)
            }

            let flattenedParams = URLEncoder.flattenParameters(parameters)
            let queryItems = flattenedParams.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
            components.queryItems = queryItems.isEmpty ? nil : queryItems

            guard let url = components.url else {
                throw URLError(.badURL)
            }

            request = URLRequest(url: url)
            
        case .post:
            // For POST requests: use form data in body
            request = URLRequest(url: endpoint.url)

            let formData = URLEncoder.queryString(from: parameters).data(using: .utf8)
            request.httpBody = formData

            if let formData {
                request.setValue(String(formData.count), forHTTPHeaderField: "Content-Length")
            }
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }

        // Common headers for all requests
        request.httpMethod = method.rawValue
        request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try Self.decoder.decode(T.self, from: data)
    }
}

extension FinancialConnectionsApiClient {
    func synchronize(
        clientSecret: String,
        returnUrl: URL
    ) async throws -> SynchronizePayload {
        let mobileParameters: [String: Any] = [
            "fullscreen": true,
            "app_return_url": returnUrl,
        ]
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "mobile": mobileParameters,
        ]
        return try await post(endpoint: .synchronize, parameters: parameters)
    }

    func fetchSessionWithAccounts(
        clientSecret: String
    ) async throws -> Session {
        // First, get the initial session
        let initialSession = try await sessionReceipt(clientSecret: clientSecret)

        // If there are no more accounts to fetch, return the session as is
        if !initialSession.accounts.hasMore {
            return initialSession
        }

        // Start with the accounts already in the session
        var allAccounts = initialSession.accounts.data
        var hasMore = initialSession.accounts.hasMore
        var lastAccountId = allAccounts.last?.id
        let maxNumberOfAccountsToFetch: Int = 100

        // Continue fetching accounts until there are no more or we've reached 100
        while hasMore && allAccounts.count < maxNumberOfAccountsToFetch {
            // Fetch next page of accounts
            let accountList = try await listAccounts(
                clientSecret: clientSecret,
                startingAfterAccountId: lastAccountId
            )
            
            // Add accounts to our collection
            allAccounts.append(contentsOf: accountList.data)
            
            // Update for next iteration
            hasMore = accountList.hasMore
            lastAccountId = accountList.data.last?.id
        }

        // Create a new AccountList with all the accounts we've fetched
        let completeAccountList = AccountList(
            data: allAccounts,
            hasMore: hasMore // Will be true if we hit the 100 account limit but there are more
        )
        
        // Create a new Session with the complete account list
        return Session(
            id: initialSession.id,
            clientSecret: initialSession.clientSecret,
            livemode: initialSession.livemode,
            accounts: completeAccountList
        )
    }
    
    private func sessionReceipt(
        clientSecret: String
    ) async throws -> Session {
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
        ]
        return try await get(endpoint: .sessionReceipt, parameters: parameters)
    }

    private func listAccounts(
        clientSecret: String,
        startingAfterAccountId: String?
    ) async throws -> AccountList {
        var parameters: [String: Any] = [
            "client_secret": clientSecret
        ]
        if let startingAfterAccountId = startingAfterAccountId {
            parameters["starting_after"] = startingAfterAccountId
        }
        return try await get(endpoint: .listAccounts, parameters: parameters)
    }
}
