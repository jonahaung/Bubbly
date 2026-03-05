//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SFSafeSymbols
import SwiftUI
import XUI

struct ChatAccessoryBar: View {
    @Environment(ChatViewManager.self) private var manager
    @Namespace private var chatNoticeView

    var body: some View {
        HStack(alignment: .bottom) {
            if let accessory = manager.presentation.state.bottomAccessory {
                Spacer()
                if accessory == .scrollDownButton {
                    AsyncButton {
                        manager.handleScrollDownButtonTap()
                    } label: {
                        Image(systemName: "chevron.down")
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                            .frame(square: 40)
                            .background(.windowBackground, in: .circle)
                    }
                }
            }
        }
        .frame(height: 40)
        .padding(.horizontal, 16)
        .geometryGroup()
    }
}
