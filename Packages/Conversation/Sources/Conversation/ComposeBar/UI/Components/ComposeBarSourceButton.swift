//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import XUI

extension ComposeBar {
    struct ComposeBarSourceButton: View {
        let source: ChatComposer.Source
        @Environment(ChatComposer.self) private var composer

        var body: some View {
            SingleSubviewLayout {
                AsyncButton(action: action) {
                    Image(systemName: source.systemImageName)
                        .resizable()
                        .frame(square: 20)
                        .foregroundStyle(source.foreGroundStyle)
                }
                .frame(square: 38)
                .background(.windowBackground, in: .circle)
            }
        }

        private func action() async {
            composer.updateSource(source)
        }
    }
}
