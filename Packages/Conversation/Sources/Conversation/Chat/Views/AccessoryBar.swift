// © 2026 Aung Ko Min

import Core
import SwiftUI
import XUI

struct AccessoryBar: View {
    @Environment(ChatManager.self) private var manager
    var body: some View {
        HStack(alignment: .bottom) {
            Spacer()
            if let accessory = manager.presentation.state.bottomAccessory {
                if accessory == .scrollDownButton {
                    CustomButton {
                        manager.handleScrollDownButtonTap()
                    } label: {
                        Image(systemName: "chevron.down")
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                            .frame(square: 40)
                            .background(Color.appPrimary, in: .circle)
                            .transition(
                                .movingParts
                                    .skid(direction: .trailing)
                                    .animation(.easeOut),
                            )
                    }
                }
            }
        }
        .frame(height: 40)
        .padding(.horizontal, 16)
        .geometryGroup()
    }
}
