//
//  MsgCellFooterView.swift
//  Conversation
//
//  Created by Aung Ko Min on 17/2/22.
//

import Core
import Database
import Services
import SwiftUI
import XUI

struct MsgCellHeader: View {
    let msg: Message
    var text: String {
        msg.isSender ? msg.date
            .formatted(date: .abbreviated, time: .shortened) : ContactStore.shared.contact(for: msg.senderID)?.name ?? "Unknown"
    }

    var body: some View {
        Text(text)
            .font(.system(size: UIFont.smallSystemFontSize, weight: .medium).smallCaps())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.horizontal, ChatLayoutConstants.Cell.defaultSpacing + 4)
            .padding(.top, 8)
            .equatable(by: msg.uid)
            .id(msg.uid + Self.typeName)
            .layoutValue(.init(uid: msg.uid + Self.typeName, recipient: msg.receiptType))
    }
}

struct MsgCellFooter: View {
    let msg: Message
    var text: String {
        msg.isSender ? msg.outgoingStatus
            .values
            .map(\.description)
            .joined(separator: ", ") : msg.date
            .formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        Text(text)
            .font(.system(size: UIFont.smallSystemFontSize, weight: .medium).smallCaps())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.horizontal, ChatLayoutConstants.Cell.defaultSpacing + 4)
            .padding(.bottom, 8)
            .equatable(by: msg.uid)
            .id(msg.uid + Self.typeName)
            .layoutValue(.init(uid: msg.uid + Self.typeName, recipient: msg.receiptType))
    }
}

struct MsgCellFooterView: View {
    private let text: String
    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(.init(text))
            .font(.system(size: UIFont.smallSystemFontSize, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .equatable(by: text)
    }
}
