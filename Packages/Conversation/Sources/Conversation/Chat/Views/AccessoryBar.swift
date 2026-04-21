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
                switch accessory {
                case .scrollDownButton:
                    CircleButton(.arrowshapeDownFill) {
                        manager.send(.scrollDownButtonTapped)
                    }
                    .transition(
                        .movingParts
                            .skid(direction: .trailing)
                            .animation(.easeOut),
                    )
                case .keyboardButton:
                    CircleButton(.keyboardChevronCompactDown) {
                        UIApplication.shared.endEditing()
                    }
                    .transition(
                        .movingParts
                            .skid(direction: .trailing)
                            .animation(.easeOut),
                    )
                case .contactAvator:
                    ZeroSizeView()
                }
            }
        }
        .frame(height: 40)
        .padding(.horizontal, Padding.sm)
        .padding(.bottom, Padding.sm)
        .geometryGroup()
    }
}
