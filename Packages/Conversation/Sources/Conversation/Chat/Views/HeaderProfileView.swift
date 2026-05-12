//  HeaderProfileView.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database

struct HeaderProfileView: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(conversation.name)
                .bold()
            Text(conversation.preetyPrinted)
                .font(.system(.footnote, design: .serif))
        }
        .frame(maxWidth: .infinity, minHeight: UIApplication.shared.screenSize().height)
        .padding(Padding.md)
        .background(.windowBackground)
        .containerShape(RoundedRectangle(cornerRadius: Radius.card))
        .padding(.vertical, Padding.md)
        .id(conversation.uid)
        .equatable(by: conversation.uid)
        .layoutValue(
            key: MsgLayoutValueKey.self,
            value: .init(uid: conversation.uid, recipient: .system, attachmentsCount: 0, headerID: 0)
        )
    }
}
