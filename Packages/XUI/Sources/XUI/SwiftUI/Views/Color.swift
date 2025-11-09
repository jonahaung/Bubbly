//
//  Color.swift
//  MoreUI
//
//  Created by Aung Ko Min on 10/27/21.

import SwiftUI

public extension Color {
    var hue: CGFloat {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        let couldBeConverted = UIColor.red.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
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
    static var label: Color { Self(UIColor.label) }
    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var secondaryLabel: Color { Self(UIColor.secondaryLabel) }
    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var tertiaryLabel: Color { Self(UIColor.tertiaryLabel) }
    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var quaternaryLabel: Color { Self(UIColor.quaternaryLabel) }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var systemFill: Color { Self(UIColor.systemFill) }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var secondarySystemFill: Color {
        Self(UIColor.secondarySystemFill)
    }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var tertiarySystemFill: Color {
        Self(UIColor.tertiarySystemFill)
    }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var quaternarySystemFill: Color {
        Self(UIColor.quaternarySystemFill)
    }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var placeholderText: Color { Self(UIColor.placeholderText) }

    @available(iOS 13.0, macCatalyst 13.0, *)
    static var systemBackground: Color { Self(UIColor.systemBackground) }

    @available(iOS 13.0, macCatalyst 13.0, *)
    static var secondarySystemBackground: Color { Self(UIColor.secondarySystemBackground) }

    @available(iOS 13.0, macCatalyst 13.0, *)
    static var tertiarySystemBackground: Color { Self(UIColor.tertiarySystemBackground) }

    @available(iOS 13.0, macCatalyst 13.0, *)
    static var systemGroupedBackground: Color {
        Self(UIColor.systemGroupedBackground)
    }

    @available(iOS 13.0, macCatalyst 13.0, *)
    static var secondarySystemGroupedBackground: Color {
        Self(UIColor.secondarySystemGroupedBackground)
    }

    @available(iOS 13.0, macCatalyst 13.0, *)
    static var tertiarySystemGroupedBackground: Color {
        Self(UIColor.tertiarySystemGroupedBackground)
    }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var separator: Color { Self(UIColor.separator) }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var opaqueSeparator: Color { Self(UIColor.opaqueSeparator) }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var link: Color { Self(UIColor.link) }
    static var darkText: Color { Self(UIColor.darkText) }
    static var lightText: Color { Self(UIColor.lightText) }
}

// SwiftUI Standard Colors
public extension Color {
    // MARK: - Adaptable Colors

    /// A blue color that automatically adapts to the current trait environment.
    static var systemBlue: Color { Self(UIColor.systemBlue) }
    /// A brown color that automatically adapts to the current trait environment.
    static var systemBrown: Color { Self(UIColor.systemBrown) }
    /// A green color that automatically adapts to the current trait environment.
    static var systemGreen: Color { Self(UIColor.systemGreen) }
    /// An indigo color that automatically adapts to the current trait environment.
    static var systemIndigo: Color { Self(UIColor.systemIndigo) }
    /// An orange color that automatically adapts to the current trait environment.
    static var systemOrange: Color { Self(UIColor.systemOrange) }
    /// A pink color that automatically adapts to the current trait environment.
    static var systemPink: Color { Self(UIColor.systemPink) }
    /// A purple color that automatically adapts to the current trait environment.
    static var systemPurple: Color { Self(UIColor.systemPurple) }
    /// A red color that automatically adapts to the current trait environment.
    static var systemRed: Color { Self(UIColor.systemRed) }
    /// A teal color that automatically adapts to the current trait environment.
    static var systemTeal: Color { Self(UIColor.systemTeal) }
    /// A yellow color that automatically adapts to the current trait environment.
    static var systemYellow: Color { Self(UIColor.systemYellow) }
    /// A cyan color that automatically adapts to the current trait environment.
    static var systemCyan: Color { Self(UIColor.systemCyan) }
    /// A mint color that automatically adapts to the current trait environment.
    static var systemMint: Color { Self(UIColor.systemMint) }
    /// The first nondefault tint color value in the view’s hierarchy, ascending from and starting with the view itself.
    static var tintColor: Color { Self(UIColor.tintColor) }

    static var systemGray: Color { Self(UIColor.systemGray) }

    static var systemGray2: Color { Self(UIColor.systemGray2) }

    static var systemGray3: Color { Self(UIColor.systemGray3) }

    static var systemGray4: Color { Self(UIColor.systemGray4) }

    static var systemGray5: Color { Self(UIColor.systemGray5) }

    static var systemGray6: Color { Self(UIColor.systemGray5) }

    static var cyan: Color { Self(UIColor.cyan) }
    /// A color object with a grayscale value of 1/3 and an alpha value of `1.0`.
    static var darkGray: Color { Self(UIColor.darkGray) }
    /// A color object with a grayscale value of 2/3 and an alpha value of `1.0`.
    static var lightGray: Color { Self(UIColor.lightGray) }
    /// A color object with RGB values of `1.0`, `0.0`, and `1.0`, and an alpha value of `1.0`.
    static var magenta: Color { Self(UIColor.magenta) }
}

/// Conformation to `CaseIterable` protocol.
extension Color: @retroactive CaseIterable {
    public static var allCases: [Color] {
        [.systemCyan, systemMint, .tintColor, .label, .secondaryLabel, .tertiaryLabel, .quaternaryLabel, .systemFill, .secondarySystemFill, .tertiarySystemFill, .quaternarySystemFill, .placeholderText, .systemBackground, .secondarySystemBackground, .tertiarySystemBackground, .systemGroupedBackground, .secondarySystemGroupedBackground, .tertiarySystemGroupedBackground, .separator, .opaqueSeparator, .link, .darkText, .lightText, .systemBlue, systemBrown, .systemGreen, .systemIndigo, .systemOrange, .systemPink, .systemPurple, .systemRed, .systemTeal, .systemYellow, .systemGray, .systemGray2, .systemGray3, .systemGray4, .systemGray5, .systemGray6, .clear, .black, .blue, .brown, .cyan, .darkGray, .gray, .green, .lightGray, .magenta, .orange, .purple, .red, .white, .yellow].sorted(by: { $0.hue < $1.hue })
    }
}

/// Conformation to `Comparable` protocol
extension Color: @retroactive Comparable {
    public static func < (lhs: Color, rhs: Color) -> Bool {
        lhs.hue < rhs.hue
    }
}

/// More color sets.
public extension Color {
    static var rainbow: [Color] {
        [.red, .orange, .yellow, .green, .blue, .cyan, .systemRed, .systemOrange, .systemYellow, .systemIndigo, .purple, .systemPink, .magenta, .systemGreen, .systemBlue, .systemCyan, .systemMint, .systemPurple, .systemTeal].sorted(by: { $0.hue < $1.hue })
    }

    static var systemColors: [Color] {
        [.systemRed, .systemMint, .systemCyan, .systemBlue, .systemGray, .systemBrown, .systemGreen, .systemPurple, .systemIndigo, .systemYellow, .systemOrange, .systemPink, .systemTeal, .systemBrown, .systemPurple].sorted(by: { $0.hue < $1.hue })
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
        [.systemGroupedBackground, .secondarySystemGroupedBackground, .tertiarySystemGroupedBackground]
    }

    static var separatorColors: [Color] {
        [.separator, .opaqueSeparator]
    }

    static var nonadaptableColors: [Color] {
        [.darkText, .lightText]
    }

    static var adaptableColors: [Color] {
        [.systemBlue, .systemBrown, .systemGreen, .systemIndigo, .systemOrange, .systemPink, .systemPurple, .systemRed, .systemTeal, .systemYellow]
    }

    static var adaptableGrayColors: [Color] {
        [.systemGray, .systemGray2, .systemGray3, .systemGray4, .systemGray5, .systemGray6]
    }

    static var fixedColors: [Color] {
        [.black, .blue, .brown, .cyan, .darkGray, .gray, .green, .lightGray, .magenta, .orange, .purple, .red, .white, .yellow]
    }
}
