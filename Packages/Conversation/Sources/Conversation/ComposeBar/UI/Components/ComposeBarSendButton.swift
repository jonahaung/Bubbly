//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import SwiftUI
import XUI

extension ComposeBar {
    struct ComposeBarSendButton: View {
        @Environment(ChatComposer.self) private var composer: ChatComposer
        @Environment(ChatViewManager.self) private var manager

        var body: some View {
            SingleSubviewLayout {
                AsyncButton {
                    if composer.hasContent {
                        composer.send(conversation: manager.conversation)
                    } else {
                        composer.inputText.text = Lorem.random()
                    }
                } label: {
                    Image(systemName: imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(square: 24)
                }
                .frame(width: 44, height: 44, alignment: .center)
                .background(.windowBackground, in: .circle)
                .overlay {
                    if composer.isLoading {
                        LoadingIndicator(43)
                            .opacity(0.5)
                    }
                }
            }
        }

        var imageName: String {
            composer.hasContent ? "paperplane.fill" : "character.cursor.ibeam"
        }
    }
}
