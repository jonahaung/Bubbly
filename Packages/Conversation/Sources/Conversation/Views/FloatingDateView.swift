//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

//
//  FloatingDateView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 27/4/25.
//
import SwiftUI

struct FloatingDateView: View {

    @Environment(ChatViewManager.self) private var manager

    var body: some View {
        if let string = manager.presentation.state.dateText {
            Text(string)
                .font(.footnote.bold())
                .lineHeight(.normal)
                .lineSpacing(0)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(manager.conversation.properties.theme.background.color, in: .capsule)
        }
    }
}
