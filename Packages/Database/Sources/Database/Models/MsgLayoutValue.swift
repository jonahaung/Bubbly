//
//  MsgLayoutValue.swift
//  Database
//
//  Created by Aung Ko Min on 20/5/26.
//

import SwiftUI

public struct MsgLayoutValue: Sendable, Hashable, UIdentifiable {

    public let uid: String
    public let recipient: MsgRecipient
    public let hasAttachment: Bool
    public let headerID: Int
    public let isSelected: Bool

    public init(
        uid: String,
        recipient: MsgRecipient,
        hasAttachment: Bool,
        headerID: Int,
        isSelected: Bool
    ) {
        self.uid = uid
        self.recipient = recipient
        self.hasAttachment = hasAttachment
        self.headerID = headerID
        self.isSelected = isSelected
    }
}

public extension MsgLayoutValue {

    var anchor: UnitPoint {
        switch recipient {
        case .outgoing:
            .topTrailing
        case .incoming:
            .topLeading
        case .system:
            .top
        }
    }

    static let empty: Self = .init(
        uid: String(),
        recipient: .outgoing,
        hasAttachment: false,
        headerID: 0,
        isSelected: false
    )
}

public struct MsgLayoutValueKey: LayoutValueKey {
    public static let defaultValue: MsgLayoutValue = .empty
}
