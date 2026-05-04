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
    let headerID: Int
}

extension MsgLayoutValue {
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

    static let empty: MsgLayoutValue = .init(
        uid: String(),
        recipient: .outgoing,
        attachmentsCount: 0,
        headerID: 0
    )
}

struct MsgLayoutValueKey: LayoutValueKey {
    static let defaultValue: MsgLayoutValue = .empty
}

extension Message {
    func layoutValue(layout: MsgCellLayout) -> MsgLayoutValue {
        .init(
            uid: uid,
            recipient: receiptType,
            attachmentsCount: attachments?.count ?? 0,
            headerID: layout.id
        )
    }
}

extension ContainerValues {
    @Entry var viewIsVisible = false
}
