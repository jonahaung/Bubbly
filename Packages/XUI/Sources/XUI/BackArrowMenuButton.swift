//  BackArrowMenuButton.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public struct BackArrowMenuButton: View {

    @Binding private var isOpen: Bool
    private let size: CGFloat
    private let barColor: Color
    private let cornerRadius: CGFloat

    public init(
        isOpen: Binding<Bool>,
        size: CGFloat = 64,
        barColor: Color = .primary,
        cornerRadius: CGFloat = 5
    ) {
        _isOpen = isOpen
        self.size = size
        self.barColor = barColor
        self.cornerRadius = cornerRadius
    }

    private var barHeight: CGFloat {
        size * 0.15
    }

    private var barSpacing: CGFloat {
        size * 0.22
    }

    private var springAnimation: Animation {
        let spring = SwiftUI.Spring(mass: 1, stiffness: 200, damping: 20)
        return Animation.spring(spring)
    }

    public var body: some View {
        let offsetX = size * 0.25
        let shrinkWidth = size * 0.75

        Button {
            withAnimation(springAnimation) {
                isOpen.toggle()
            }
        } label: {
            VStack(spacing: isOpen ? -barSpacing * 0.85 : barSpacing) {

                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(barColor)
                    .frame(width: isOpen ? shrinkWidth : size, height: barHeight)
                    .rotationEffect(.degrees(isOpen ? -30 : 0), anchor: .leading)
                    .offset(x: isOpen ? -offsetX : 0)

                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(barColor)
                    .frame(width: size, height: barHeight)
                    .scaleEffect(x: isOpen ? 1.2 : 1, anchor: .leading)

                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(barColor)
                    .frame(width: isOpen ? shrinkWidth : size, height: barHeight)
                    .rotationEffect(.degrees(isOpen ? 30 : 0), anchor: .leading)
                    .offset(x: isOpen ? -offsetX : 0)
            }
            .rotationEffect(.degrees(isOpen ? 90 : 0), anchor: .center)
            .frame(width: size, height: size)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
