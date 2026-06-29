//  ComposeBarSendButton.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import Database
import SwiftUI
import XUI

extension ComposeBar {
    struct ComposeBarSendButton: View {
        @Environment(ChatComposer.self) private var composer: ChatComposer
        @Environment(ChatManager.self) private var manager

        var body: some View {
            AsyncButton {
                if composer.canSend {
                    composer.send(conversation: manager.state.conversation)
                } else {
                    composer.inputText.set(text: Lorem.random())
                }
            } label: {
                ZStack {
                    if composer.state.isProcessing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(square: 24)
                            .foregroundStyle(
                                composer.hasContent ? .primary : .secondary
                            )
                            .padding()
                            .rotationEffect(
                                .degrees(composer.hasContent ? -45 : -180),
                                anchor: .center
                            )
                            .animation(
                                .anticipateOvershoot,
                                value: composer.hasContent
                            )
                    }
                }
                .frame(
                    width: ChatLayoutConstants.bottomBarHeight,
                    height: ChatLayoutConstants.bottomBarHeight,
                    alignment: .center
                )
                .background(Color.appPrimary, in: .circle)
                .geometryGroup()
            }
//            .disabled(composer.canSend == false)
            .accessibilityLabel("Send message")
        }
    }
}
