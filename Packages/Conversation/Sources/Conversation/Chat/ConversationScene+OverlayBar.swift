//  ConversationScene+OverlayBar.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI
import Database
import Services

struct ConversationSceneOverlayBar: View {
    @Environment(ChatManager.self) private var manager
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            TopBar()
            AsyncButton {
                
            } label: {
                switch manager.state.conversation.kind {
                case let .contact(contact):
                    ProfilePhoto(
                        contact,
                        size: .custom(26), tapAction: .none
                    )
                case let .group(group):
                    ProfilePhoto(
                        group,
                        size: .custom(26), tapAction: .none
                    )
                }
            }
            FloatingDateView()
            Spacer()
            AccessoryBar()
            ComposeBar()
        }
    }
}
