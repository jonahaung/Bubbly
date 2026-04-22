//  Color.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

public extension Color {
    var hue: CGFloat {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        let couldBeConverted = UIColor.red.getHue(
            &hue,
            saturation: &saturation,
            brightness: &brightness,
            alpha: &alpha
        )
        if couldBeConverted {
            return hue
        }
        return 0
    }

    var uiColor: UIColor {
        UIColor(self)
    }
}

public extension Color {
    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var label: Color {
        Self(.label)
    }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var secondaryLabel: Color {
        Self(.secondaryLabel)
    }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var tertiaryLabel: Color {
        Self(.tertiaryLabel)
    }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var quaternaryLabel: Color {
        Self(.quaternaryLabel)
    }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var systemFill: Color {
        Self(.systemFill)
    }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var secondarySystemFill: Color {
        Self(.secondarySystemFill)
    }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var tertiarySystemFill: Color {
        Self(.tertiarySystemFill)
    }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var quaternarySystemFill: Color {
        Self(.quaternarySystemFill)
    }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var placeholderText: Color {
        Self(.placeholderText)
    }

    @available(iOS 13.0, macCatalyst 13.0, *)
    static var systemBackground: Color {
        Self(.systemBackground)
    }

    @available(iOS 13.0, macCatalyst 13.0, *)
    static var secondarySystemBackground: Color {
        Self(.secondarySystemBackground)
    }

    @available(iOS 13.0, macCatalyst 13.0, *)
    static var tertiarySystemBackground: Color {
        Self(.tertiarySystemBackground)
    }

    @available(iOS 13.0, macCatalyst 13.0, *)
    static var systemGroupedBackground: Color {
        Self(.systemGroupedBackground)
    }

    @available(iOS 13.0, macCatalyst 13.0, *)
    static var secondarySystemGroupedBackground: Color {
        Self(.secondarySystemGroupedBackground)
    }

    @available(iOS 13.0, macCatalyst 13.0, *)
    static var tertiarySystemGroupedBackground: Color {
        Self(.tertiarySystemGroupedBackground)
    }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var separator: Color {
        Self(.separator)
    }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var opaqueSeparator: Color {
        Self(.opaqueSeparator)
    }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var link: Color {
        Self(.link)
    }

    static var darkText: Color {
        Self(.darkText)
    }

    static var lightText: Color {
        Self(.lightText)
    }
}

/// SwiftUI Standard Colors
public extension Color {
    static var systemBlue: Color {
        Self(.systemBlue)
    }

    static var systemBrown: Color {
        Self(.systemBrown)
    }

    static var systemGreen: Color {
        Self(.systemGreen)
    }

    static var systemIndigo: Color {
        Self(.systemIndigo)
    }

    static var systemOrange: Color {
        Self(.systemOrange)
    }

    static var systemPink: Color {
        Self(.systemPink)
    }

    static var systemPurple: Color {
        Self(.systemPurple)
    }

    static var systemRed: Color {
        Self(.systemRed)
    }

    static var systemTeal: Color {
        Self(.systemTeal)
    }

    static var systemYellow: Color {
        Self(.systemYellow)
    }

    static var systemCyan: Color {
        Self(.systemCyan)
    }

    static var systemMint: Color {
        Self(.systemMint)
    }

    static var tintColor: Color {
        Self(.tintColor)
    }

    static var systemGray: Color {
        Self(.systemGray)
    }

    static var systemGray2: Color {
        Self(.systemGray2)
    }

    static var systemGray3: Color {
        Self(.systemGray3)
    }

    static var systemGray4: Color {
        Self(.systemGray4)
    }

    static var systemGray5: Color {
        Self(.systemGray5)
    }

    static var systemGray6: Color {
        Self(.systemGray5)
    }

    static var cyan: Color {
        Self(.cyan)
    }

    static var darkGray: Color {
        Self(.darkGray)
    }

    static var lightGray: Color {
        Self(.lightGray)
    }

    static var magenta: Color {
        Self(.magenta)
    }
}

extension Color: @retroactive CaseIterable {
    public static var allCases: [Color] {
        [
            .systemCyan, systemMint, .tintColor, .label, .secondaryLabel, .tertiaryLabel,
            .quaternaryLabel,
            .systemFill, .secondarySystemFill, .tertiarySystemFill, .quaternarySystemFill,
            .placeholderText,
            .systemBackground, .secondarySystemBackground, .tertiarySystemBackground,
            .systemGroupedBackground,
            .secondarySystemGroupedBackground, .tertiarySystemGroupedBackground, .separator,
            .opaqueSeparator, .link,
            .darkText, .lightText, .systemBlue, systemBrown, .systemGreen, .systemIndigo,
            .systemOrange, .systemPink,
            .systemPurple, .systemRed, .systemTeal, .systemYellow, .systemGray, .systemGray2,
            .systemGray3,
            .systemGray4, .systemGray5, .systemGray6, .clear, .black, .blue, .brown, .cyan,
            .darkGray, .gray,
            .green, .lightGray, .magenta, .orange, .purple, .red, .white, .yellow
        ].sorted(by: { $0.hue < $1.hue })
    }
}

extension Color: @retroactive Comparable {
    public static func < (lhs: Color, rhs: Color) -> Bool {
        lhs.hue < rhs.hue
    }
}

public extension Color {
    static var rainbow: [Color] {
        [
            .red, .orange, .yellow, .green, .blue, .cyan, .systemRed, .systemOrange, .systemYellow,
            .systemIndigo,
            .purple, .systemPink, .magenta, .systemGreen, .systemBlue, .systemCyan, .systemMint,
            .systemPurple,
            .systemTeal
        ].sorted(by: { $0.hue < $1.hue })
    }

    static var systemColors: [Color] {
        [
            .systemRed, .systemMint, .systemCyan, .systemBlue, .systemGray, .systemBrown,
            .systemGreen, .systemPurple,
            .systemIndigo, .systemYellow, .systemOrange, .systemPink, .systemTeal, .systemBrown,
            .systemPurple
        ].sorted(by: { $0.hue < $1.hue })
    }

    static var labelColors: [Color] {
        [.label, .secondaryLabel, .tertiaryLabel, .quaternaryLabel]
    }

    static var fillColors: [Color] {
        [.systemFill, .secondarySystemFill, .tertiarySystemFill, .quaternarySystemFill]
    }

    static var standardContentBackgroundColors: [Color] {
        [.systemBackground, .secondarySystemBackground, .tertiarySystemBackground]
    }

    static var groupedContentBackgroundColors: [Color] {
        [
            .systemGroupedBackground,
            .secondarySystemGroupedBackground,
            .tertiarySystemGroupedBackground
        ]
    }

    static var separatorColors: [Color] {
        [.separator, .opaqueSeparator]
    }

    static var nonadaptableColors: [Color] {
        [.darkText, .lightText]
    }

    static var adaptableColors: [Color] {
        [
            .systemBlue,
            .systemBrown,
            .systemGreen,
            .systemIndigo,
            .systemOrange,
            .systemPink,
            .systemPurple,
            .systemRed,
            .systemTeal,
            .systemYellow
        ]
    }

    static var adaptableGrayColors: [Color] {
        [.systemGray, .systemGray2, .systemGray3, .systemGray4, .systemGray5, .systemGray6]
    }

    static var fixedColors: [Color] {
        [
            .black,
            .blue,
            .brown,
            .cyan,
            .darkGray,
            .gray,
            .green,
            .lightGray,
            .magenta,
            .orange,
            .purple,
            .red,
            .white,
            .yellow
        ]
    }
}
