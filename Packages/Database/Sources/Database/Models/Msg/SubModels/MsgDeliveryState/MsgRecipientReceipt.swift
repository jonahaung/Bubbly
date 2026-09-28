//  MsgRecipientReceipt.swift
//
//  Copyright © 2026 Aung Ko Min.
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
        userID = memberID
        status = state
        date = updatedAt
        self.failure = failure
    }
}

extension MsgRecipientReceipt: Identifiable {
    public var id: String { userID }
}
