//
//  MsgDeliveryState.swift
//  Database
//
//  Created by Aung Ko Min on 25/4/26.
//

import Foundation

public struct MsgDeliveryState: Sendable, Equatable, Hashable, Codable {

    public let msgID: String
    public let receipts: [MsgRecipientReceipt]

    public init(msgID: String, receipts: [MsgRecipientReceipt]) {
        self.msgID = msgID
        self.receipts = receipts
    }

    public init(
        msgID: String,
        recipientIDs: [String],
        initialState: DeliveryStatus,
        updatedAt: ServerTime = .now
    ) {
        self.init(
            msgID: msgID,
            receipts: recipientIDs.map {
                MsgRecipientReceipt(
                    memberID: $0,
                    state: initialState,
                    updatedAt: updatedAt
                )
            }
        )
    }

    public init(
        msgID: String,
        senderID: String,
        aggregateStatus: DeliveryStatus,
        recipientIDs: [String],
        updatedAt: ServerTime = .now
    ) {
        if aggregateStatus == .sending, recipientIDs.isEmpty {
            self.init(msgID: msgID, receipts: [])
        } else {
            self.init(
                msgID: msgID,
                recipientIDs: recipientIDs,
                initialState: aggregateStatus,
                updatedAt: updatedAt
            )
        }
    }
}

extension MsgDeliveryState {
    public mutating func updatingReceipt(
        memberID: String,
        state: DeliveryStatus,
        updatedAt: ServerTime = .now,
        failure: DeliveryFailure? = nil
    ) {
        var receipts = receipts
        if let index = receipts.firstIndex(where: {
            $0.userID == memberID
        }) {
            receipts[index] = MsgRecipientReceipt(
                memberID: memberID,
                state: state,
                updatedAt: updatedAt,
                failure: failure
            )
        } else {
            receipts.append(
                MsgRecipientReceipt(
                    memberID: memberID,
                    state: state,
                    updatedAt: updatedAt,
                    failure: failure
                )
            )
        }
        self = Self(msgID: msgID, receipts: receipts)
    }

    public func updatingAllReceipts(
        to state: DeliveryStatus,
        updatedAt: ServerTime = .now,
        failure: DeliveryFailure? = nil
    ) -> Self {
        Self(
            msgID: msgID,
            receipts: receipts.map {
                MsgRecipientReceipt(
                    memberID: $0.userID,
                    state: state,
                    updatedAt: updatedAt,
                    failure: failure
                )
            }
        )
    }

    public var localizedName: String { aggregateStatus.localizedName }
    public func replacingReceipts(_ receipts: [MsgRecipientReceipt]) -> Self {
        Self(msgID: msgID, receipts: receipts)
    }

    public func state(for recipientID: String) -> DeliveryStatus? {
        receipts.first(where: { $0.userID == recipientID })?.status
    }
}

extension MsgDeliveryState {
    public var aggregateStatus: DeliveryStatus {
        guard !receipts.isEmpty else { return .sending }
        if receipts.contains(where: { $0.status == .partiallyFailed }) {
            return .partiallyFailed
        }
        if receipts.allSatisfy({ $0.status == .read }) { return .read }
        if receipts.allSatisfy({
            $0.status >= .delivered
        }) {
            return .delivered
        }
        if receipts.allSatisfy({
            $0.status >= .initial
        }) {
            return .initial
        }
        return .sending
    }

    public static let empty: MsgDeliveryState = .init(
        msgID: String(),
        receipts: []
    )
}
