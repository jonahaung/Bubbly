//  ComposeBarSendButton.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database

extension ComposeBar {
    struct ComposeBarSendButton: View {
        @Environment(ChatComposer.self) private var composer: ChatComposer
        @Environment(ChatManager.self) private var manager

        var body: some View {
            AsyncButton {
                if composer.hasContent {
                    composer.send(conversation: manager.state.conversation)
                } else {
                    composer.inputText.text = Lorem.random()
                }
            } label: {
                ZStack {
                    let hasText = composer.hasContent
                    Image(systemName: "paperplane.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(square: 24)
                        .foregroundStyle(hasText ? .primary : .secondary)
                        .padding()
                        .rotationEffect(
                            .degrees(hasText ? -45 : -180),
                            anchor: .center
                        )
                        .animation(.anticipateOvershoot, value: hasText)
                }
                .frame(
                    width: ChatLayoutConstants.bottomBarHeight,
                    height: ChatLayoutConstants.bottomBarHeight,
                    alignment: .center
                )
                .background(Color.appPrimary, in: .circle)
                .geometryGroup()
            }
        }
    }
}
