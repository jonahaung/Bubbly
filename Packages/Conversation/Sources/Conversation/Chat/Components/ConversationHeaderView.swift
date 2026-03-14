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
        .background(.windowBackground, in: RoundedRectangle(cornerRadius: 12))
        .padding()
        .id(Self.typeName)
    }
}
