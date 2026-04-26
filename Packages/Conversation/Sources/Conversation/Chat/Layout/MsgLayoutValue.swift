//  MsgLayoutValue.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database
import Services

struct MsgLayoutValue: Sendable, Hashable, Equatable, UIdentifiable {
    let uid: String
    let recipient: MsgRecipient
    let attachmentsCount: Int
    let headerStatus: Int

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

    static func == (lhs: MsgLayoutValue, rhs: MsgLayoutValue) -> Bool {
        lhs.uid == rhs.uid && lhs.recipient == rhs.recipient && lhs.headerStatus == rhs.headerStatus
    }

    static let empty: MsgLayoutValue = .init(
        uid: String(),
        recipient: .outgoing,
        attachmentsCount: 0,
        headerStatus: 0
    )
}

struct MsgLayoutValueKey: LayoutValueKey {
    static let defaultValue: MsgLayoutValue = .empty
}

extension Message {
    func layoutValue(layout: MsgCellLayout) -> MsgLayoutValue {
        let headerStatus: Int = {
            let timeSeparator = layout.showTimeSeparator ? 1 : 0
            let topPadding = layout.showTopPadding ? 2 : 0
            return timeSeparator + topPadding
        }()
        return .init(
            uid: uid,
            recipient: receiptType,
            attachmentsCount: attachments?.count ?? 0,
            headerStatus: headerStatus
        )
    }
}

extension ContainerValues {
    @Entry var viewIsVisible = false
}
