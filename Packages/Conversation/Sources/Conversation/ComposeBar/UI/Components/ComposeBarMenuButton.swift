//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import PhotosUI
import SwiftUI
import XUI

extension ComposeBar {
    struct ComposeBarMenuButton: View {
        @Environment(ChatComposer.self) private var composer: ChatComposer
        @Environment(\.sharedFocusState) private var sharedFocus

        var body: some View {
            SingleSubviewLayout {
                AsyncButton {
                    let isMenu = composer.source == .menu
                    composer.updateSource(isMenu ? .text : .menu)
                } label: {
                    TwoLinesShape()
                        .frame(square: 24)
                        .frame(square: 44)
                        .background(
                            .windowBackground,
                            in: RoundedRectangle(cornerRadius: 22, style: .circular)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
