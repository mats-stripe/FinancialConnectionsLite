//
//  Session.swift
//  FinancialConnectionsLite
//
//  Created by Mat Schmid on 2025-03-11.
//

import Foundation

/// https://docs.stripe.com/api/financial_connections/sessions/object
public struct Session: Decodable {
    /// A unique ID for this session.
    public let id: String
    /// The client secret for this session.
    public let clientSecret: String
    /// Has the value true if the object exists in live mode or the value false if the object exists in test mode.
    public let livemode: Bool
    /// The accounts that were collected as part of this Session.
    public let accounts: AccountList
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientSecret = "client_secret"
        case livemode
        case accounts
    }
}

public struct AccountList: Decodable {
    public let data: [Account]
    /// True if this list has another page of items after this one that can be fetched.
    public let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
    }
}

public struct Account: Decodable {
    /// A unique ID for this Financial Connections Account.
    public let id: String
    /// Has the value true if the object exists in live mode or the value false if the object exists in test mode.
    public let livemode: Bool
    public let displayName: String?
    /// The current status of the account. Either active, inactive, or disconnected.
    public let status: AccountStatus
    public let institutionName: String
    public let last4: String?
    /// The UNIX timestamp (in milliseconds) of the date this account was created.
    public let created: Int
    /// The balance of this account.
    public let balance: Balance?
    /// The last balance refresh. Includes the timestamp and the status.
    public let balanceRefresh: BalanceRefresh?
    /// The category of this account, either cash, credit, investment, or other.
    public let category: Category
    /// The subcategory of this account, either checking, credit_card, line_of_credit, mortgage, savings, or other.
    public let subcategory: Subcategory
    /// Permissions requested for accounts collected during this session.
    public let permissions: [Permission]?
    /// The supported payment method types for this account.
    public let supportedPaymentMethodTypes: [PaymentMethodType]
    
    enum CodingKeys: String, CodingKey {
        case id
        case livemode
        case displayName = "display_name"
        case status
        case institutionName = "institution_name"
        case last4
        case created
        case balance
        case balanceRefresh = "balance_refresh"
        case category
        case subcategory
        case permissions
        case supportedPaymentMethodTypes = "supported_payment_method_types"
    }
}

public struct Balance: Decodable {
    /// The UNIX timestamp (in milliseconds) of time that the external institution calculated this balance.
    public let asOf: Int
    /// The type of this balance, either cash or credit.
    public let type: BalanceType
    /// The funds available to the account holder. Typically this is the current balance less any holds.
    public let cash: [String: Int]?
    /// The credit that has been used by the account holder.
    public let credit: [String: Int]?
    /// The balances owed to (or by) the account holder.
    public let current: [String: Int]
    
    enum CodingKeys: String, CodingKey {
        case asOf = "as_of"
        case type
        case cash
        case credit
        case current
    }
}

public struct BalanceRefresh: Decodable {
    public let status: BalanceRefreshStatus
    /// The UNIX timestamp (in milliseconds) of the time at which the last refresh attempt was initiated.
    public let lastAttemptedAt: Int
    
    enum CodingKeys: String, CodingKey {
        case status
        case lastAttemptedAt = "last_attempted_at"
    }
}

public enum AccountStatus: String, Decodable {
    case active
    case inactive
    case disconnected
}

public enum Category: String, Decodable {
    case cash
    case credit
    case investment
    case other
}

public enum PaymentMethodType: String, Decodable {
    case usBankAccount = "us_bank_account"
    case link
}

public enum Permission: String, Decodable {
    case balances
    case ownership
    case paymentMethod
    case transactions
    case accountNumbers
}

public enum Subcategory: String, Decodable {
    case checking
    case creditCard = "credit_card"
    case lineOfCredit = "line_of_credit"
    case mortgage
    case savings
    case other
}

public enum BalanceType: String, Codable {
    case cash
    case credit
}

public enum BalanceRefreshStatus: String, Codable {
    case failed
    case pending
    case succeeded
}
