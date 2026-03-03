//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI
import XUI

struct ConversationHeaderView: View {
    @Environment(ChatViewManager.self) private var manager

    var body: some View {
        VStack {
            Text(manager.conversation.name)
                .bold()
            Divider()
            Text(.init(manager.conversation.preetyPrinted))
                .font(.system(size: 12, weight: .regular, design: .default).width(.condensed))
                .textSelection(.enabled)
        }
        .padding()
        .background(
            Color.secondarySystemGroupedBackground,
            in: RoundedRectangle(
                cornerRadius: 12
            )
        )
        .lineHeight(.multiple(factor: 1.2))
        .lineSpacing(0)
        .allowsTightening(true)
        .id(Self.typeName)
        .layoutValue(
            key: MsgLayoutValueKey.self,
            value: .init(uid: manager.conversation.uid)
        )
    }
}
