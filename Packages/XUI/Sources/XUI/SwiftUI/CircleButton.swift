//  CircleButton.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI
import SFSafeSymbols

// MARK: - Model

public struct CircleButton: View {
    public let symbol: SFSymbol
    private let size: CGFloat
    public let color: Color
    public let action: () -> Void

    public init(
        _ symbol: SFSymbol,
        _ size: CGFloat = 40,
        color: Color = .accentColor,
        action: @escaping () -> Void
    ) {
        self.symbol = symbol
        self.size = size
        self.color = color
        self.action = action
    }

    public var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Circle().fill(Color.container)
                    .frame(square: size)
                    .layoutPriority(1)
                SystemImage(symbol, size * 0.4)
                    .foregroundStyle(color.gradient)
                    .fontWeight(.semibold)
            }
        }
        .buttonRepeatBehavior(.disabled)
        .buttonStyle(.borderless)
        .equatable(by: symbol)
    }
}
