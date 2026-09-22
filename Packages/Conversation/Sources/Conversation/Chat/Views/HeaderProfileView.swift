//  HeaderProfileView.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import Database
import SwiftUI
import XUI

struct HeaderProfileView: View {

    let conversation: Conversation
    let showHeader: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            if showHeader {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(conversation.name)
                        .bold()
                    Text(conversation.prettyPrinted)
                        .font(.system(.footnote, design: .serif))
                }
                .frame(maxWidth: .infinity)
                .padding(Padding.md)
                .background(.windowBackground)
                .containerShape(RoundedRectangle(cornerRadius: Radius.card))
                .padding(.vertical, Padding.md)
            }
        }
        .frame(height: ChatLayoutConstants.topBarHeight)
        .frame(maxWidth: .infinity)
        .id(conversation.uid)
        .layoutValue(
            key: MsgLayoutValueKey.self,
            value: .init(
                uid: conversation.uid,
                recipient: .system,
                hasAttachment: false,
                headerID: 0, isSelected: false
            )
        )
    }
}
