//
//  LinkAccountSessionManifest.swift
//  FinancialConnectionsLite
//
//  Created by Mat Schmid on 2025-02-20.
//

import Foundation

struct SynchronizePayload: Decodable {
    let manifest: LinkAccountSessionManifest
}

struct LinkAccountSessionManifest: Decodable {
    let id: String
    let hostedAuthURL: URL
    let successURL: URL
    let cancelURL: URL

    enum CodingKeys: String, CodingKey {
        case id
        case hostedAuthURL = "hosted_auth_url"
        case successURL = "success_url"
        case cancelURL = "cancel_url"
    }
}
