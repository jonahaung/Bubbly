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
			.padding(
				.init(
					top: 8,
					leading: ChatLayoutConstants.Cell.defaultSpacing + 4 + 8,
					bottom: 4,
					trailing: ChatLayoutConstants.Cell.defaultSpacing + 4 + 8
				)
			)
			.lineHeight(.tight)
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
			.padding(
				.init(
					top: 0,
					leading: ChatLayoutConstants.Cell.defaultSpacing + 4 + 8,
					bottom: 8,
					trailing: ChatLayoutConstants.Cell.defaultSpacing + 4 + 8
				)
			)
			.lineHeight(.tight)
            .equatable(by: msg.uid)
            .id(msg.uid + Self.typeName)
            .layoutValue(.init(uid: msg.uid + Self.typeName, recipient: msg.receiptType))
    }
}
