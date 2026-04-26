//  SystemImageWithShape.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI
import SFSafeSymbols

public struct SystemImageWithShape: View {
    private let icon: SFSymbol
    private let scale: CGFloat
    private let iconStyle: IconStyle

    public init(_ icon: SFSymbol, _ iconStyle: IconStyle, _ scale: CGFloat = 1) {
        self.icon = icon
        self.iconStyle = iconStyle
        self.scale = scale
    }

    public var body: some View {
        switch iconStyle {
        case let .plain(bgStyle):
            switch bgStyle {
            case .plain:
                SystemImage(icon, 20 * scale)
                    .padding(2 * scale)
            case .gray:
                SystemImage(icon, 20 * scale)
                    .padding(2 * scale)
                    .foregroundStyle(Color.gray.gradient)
            case let .color(color):
                SystemImage(icon, 20 * scale)
                    .padding(2 * scale)
                    .foregroundStyle(color.gradient)
            case .randomColor:
                SystemImage(icon, 20 * scale)
                    .padding(2 * scale)
                    .foregroundStyle(icon.rawValue.color.gradient)
            }
        case let .square(bgStyle):
            switch bgStyle {
            case .plain:
                SystemImage(icon, 15 * scale)
                    .padding(6 * scale)
                    .background(
                        Color(uiColor: .systemFill), in: RoundedRectangle(cornerRadius: 8 * scale))
            case .gray:
                SystemImage(icon, 15 * scale)
                    .foregroundStyle(Color.container.gradient)
                    .padding(6 * scale)
                    .background(.secondary, in: RoundedRectangle(cornerRadius: 8 * scale))
            case let .color(color):
                SystemImage(icon, 15 * scale)
                    .foregroundStyle(Color.container.gradient)
                    .padding(6 * scale)
                    .background(color.gradient, in: RoundedRectangle(cornerRadius: 8 * scale))
            case .randomColor:
                SystemImage(icon, 15 * scale)
                    .foregroundStyle(Color.container.gradient)
                    .padding(6 * scale)
                    .background(icon.rawValue.color.gradient, in: RoundedRectangle(cornerRadius: 8 * scale))
            }
        case let .circle(bgStyle):
            switch bgStyle {
            case .plain:
                SystemImage(icon, 15 * scale)
                    .padding(6 * scale)
                    .background(.fill, in: .circle)
            case .gray:
                SystemImage(icon, 15 * scale)
                    .foregroundStyle(Color.container.gradient)
                    .padding(6 * scale)
                    .background(.secondary, in: .circle)
            case let .color(color):
                SystemImage(icon, 15 * scale)
                    .foregroundStyle(Color.container.gradient)
                    .padding(6 * scale)
                    .background(color.gradient, in: .circle)
            case .randomColor:
                SystemImage(icon, 15 * scale)
                    .foregroundStyle(Color.container.gradient)
                    .padding(6 * scale)
                    .background(icon.rawValue.color.gradient, in: .circle)
            }
        }
    }

    public enum IconStyle: Hashable, Sendable {
        case plain(_ background: IconBackground)
        case square(_ background: IconBackground)
        case circle(_ background: IconBackground)
        public enum IconBackground: Hashable, Sendable {
            case plain
            case gray
            case color(_ color: Color)
            case randomColor
        }
    }
}
