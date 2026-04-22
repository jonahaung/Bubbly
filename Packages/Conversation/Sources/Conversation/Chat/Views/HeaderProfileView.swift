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
            //			Text(manager.state.properties.preetyPrinted)
            //				.font(.system(.footnote, design: .rounded))
            Text(conversation.preetyPrinted)
                .font(.system(.footnote, design: .rounded))
        }
        .lineHeight(.multiple(factor: 1.2))
        .frame(maxWidth: .infinity, minHeight: UIApplication.shared.screenSize().height / 2)
        .fixedSize(horizontal: false, vertical: true)
        .padding(Padding.md)
        .background(Color.container)
        .containerShape(RoundedRectangle(cornerRadius: Radius.card))
        .padding(.vertical, Padding.md)
        .id("header")
        .equatable(by: conversation.uid)
    }
}
