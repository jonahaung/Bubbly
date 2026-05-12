//
//  RecipientReceipt.swift
//  Database
//
//  Created by Aung Ko Min on 25/4/26.
//

import Foundation

public struct MsgRecipientReceipt: Sendable, Equatable, Hashable, Codable {
    public let userID: String
    public var status: DeliveryStatus
    public let date: Date
    public let failure: DeliveryFailure?
    
    public init(
        memberID: String,
        state: DeliveryStatus,
        updatedAt: Date,
        failure: DeliveryFailure? = nil
    ) {
        self.userID = memberID
        self.status = state
        self.date = updatedAt
        self.failure = failure
    }
}

extension MsgRecipientReceipt: Identifiable {
    public var id: String { userID }
}
