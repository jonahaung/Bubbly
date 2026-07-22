//  ConversationScene+OverlayBar.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database
import Services
import SwiftUI
import XUI

struct ConversationSceneOverlayBar: View {
    
    @Environment(ChatManager.self) private var manager

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            TopBar()
            FloatingDateView()
            Spacer()
            AccessoryBar(item: manager.presentation.state.bottomAccessory)
            ComposeBar()
        }
    }
}
