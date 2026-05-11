//  AccessoryBar.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Services

struct AccessoryBar: View {
    let item: AccessoryBarItem
    @Environment(ChatManager.self) private var manager
    var body: some View {
        HStack(alignment: .bottom) {
            Spacer()
            switch item {
            case .scrollDownButton:
                CircleButton(.chevronDown) {
                    manager.send(.scrollDownButtonTapped)
                }
                .transition(
                    .movingParts
                        .skid(direction: .trailing)
                        .animation(.easeOut)
                )
            case .keyboardButton:
                CircleButton(.keyboardChevronCompactDown) {
                    UIApplication.shared.endEditing()
                }
                .transition(
                    .movingParts
                        .skid(direction: .trailing)
                        .animation(.easeOut)
                )
            case .contactAvator:
                ZeroSizeView()
            }
        }
        .frame(height: 40)
        .padding(.horizontal, Padding.sm)
        .geometryGroup()
        .equatable(by: item)
    }
}
