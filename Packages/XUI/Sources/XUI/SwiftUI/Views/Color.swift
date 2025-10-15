//
//  UIColor.swift
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
	static var label: Color { return Self(UIColor.label) }
    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
	static var secondaryLabel: Color { return Self(UIColor.secondaryLabel) }
    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
	static var tertiaryLabel: Color { return Self(UIColor.tertiaryLabel) }
    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
	static var quaternaryLabel: Color { return Self(UIColor.quaternaryLabel) }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
	static var systemFill: Color { return Self(UIColor.systemFill) }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
	static var secondarySystemFill: Color {
		return Self(UIColor.secondarySystemFill)
	}

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
	static var tertiarySystemFill: Color {
		return Self(UIColor.tertiarySystemFill)
	}

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
	static var quaternarySystemFill: Color {
		return Self(UIColor.quaternarySystemFill)
	}

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
	static var placeholderText: Color { return Self(UIColor.placeholderText) }

    @available(iOS 13.0, macCatalyst 13.0, *)
	static var systemBackground: Color { return Self(UIColor.systemBackground) }

    @available(iOS 13.0, macCatalyst 13.0, *)
    static var secondarySystemBackground: Color { return Self(UIColor.secondarySystemBackground) }

    @available(iOS 13.0, macCatalyst 13.0, *)
    static var tertiarySystemBackground: Color { return Self(UIColor.tertiarySystemBackground) }

    @available(iOS 13.0, macCatalyst 13.0, *)
	static var systemGroupedBackground: Color {
		return Self(UIColor.systemGroupedBackground)
	}

    @available(iOS 13.0, macCatalyst 13.0, *)
	static var secondarySystemGroupedBackground: Color {
		return Self(UIColor.secondarySystemGroupedBackground)
	}

    @available(iOS 13.0, macCatalyst 13.0, *)
	static var tertiarySystemGroupedBackground: Color {
		return Self(UIColor.tertiarySystemGroupedBackground)
	}

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
	static var separator: Color { return Self(UIColor.separator) }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
    static var opaqueSeparator: Color { return Self(UIColor.opaqueSeparator) }

    @available(iOS 13.0, macCatalyst 13.0, tvOS 13.0, *)
	static var link: Color { return Self(UIColor.link) }
	static var darkText: Color { return Self(UIColor.darkText) }
	static var lightText: Color { return Self(UIColor.lightText) }
}

// SwiftUI Standard Colors
public extension Color {
    // MARK: - Adaptable Colors

    /// A blue color that automatically adapts to the current trait environment.
	static var systemBlue: Color { return Self(UIColor.systemBlue) }
    /// A brown color that automatically adapts to the current trait environment.
	static var systemBrown: Color { return Self(UIColor.systemBrown) }
    /// A green color that automatically adapts to the current trait environment.
    static var systemGreen: Color { return Self(UIColor.systemGreen) }
    /// An indigo color that automatically adapts to the current trait environment.
    static var systemIndigo: Color { return Self(UIColor.systemIndigo) }
    /// An orange color that automatically adapts to the current trait environment.
    static var systemOrange: Color { return Self(UIColor.systemOrange) }
    /// A pink color that automatically adapts to the current trait environment.
    static var systemPink: Color { return Self(UIColor.systemPink) }
    /// A purple color that automatically adapts to the current trait environment.
    static var systemPurple: Color { return Self(UIColor.systemPurple) }
    /// A red color that automatically adapts to the current trait environment.
    static var systemRed: Color { return Self(UIColor.systemRed) }
    /// A teal color that automatically adapts to the current trait environment.
    static var systemTeal: Color { return Self(UIColor.systemTeal) }
    /// A yellow color that automatically adapts to the current trait environment.
    static var systemYellow: Color { return Self(UIColor.systemYellow) }
    /// A cyan color that automatically adapts to the current trait environment.
    static var systemCyan: Color { return Self(UIColor.systemCyan) }
    /// A mint color that automatically adapts to the current trait environment.
    static var systemMint: Color { return Self(UIColor.systemMint) }
    /// The first nondefault tint color value in the view’s hierarchy, ascending from and starting with the view itself.
    static var tintColor: Color { return Self(UIColor.tintColor) }

    static var systemGray: Color { return Self(UIColor.systemGray) }

    static var systemGray2: Color { return Self(UIColor.systemGray2) }

    static var systemGray3: Color { return Self(UIColor.systemGray3) }

    static var systemGray4: Color { return Self(UIColor.systemGray4) }

    static var systemGray5: Color { return Self(UIColor.systemGray5) }

    static var systemGray6: Color { return Self(UIColor.systemGray5) }

    static var cyan: Color { return Self(UIColor.cyan) }
    /// A color object with a grayscale value of 1/3 and an alpha value of `1.0`.
    static var darkGray: Color { return Self(UIColor.darkGray) }
    /// A color object with a grayscale value of 2/3 and an alpha value of `1.0`.
    static var lightGray: Color { return Self(UIColor.lightGray) }
    /// A color object with RGB values of `1.0`, `0.0`, and `1.0`, and an alpha value of `1.0`.
    static var magenta: Color { return Self(UIColor.magenta) }
}

/// Conformation to `CaseIterable` protocol.
extension Color: @retroactive CaseIterable {
	public static var allCases: [Color] {
        return [.systemCyan, systemMint, .tintColor, .label, .secondaryLabel, .tertiaryLabel, .quaternaryLabel, .systemFill, .secondarySystemFill, .tertiarySystemFill, .quaternarySystemFill, .placeholderText, .systemBackground, .secondarySystemBackground, .tertiarySystemBackground, .systemGroupedBackground, .secondarySystemGroupedBackground, . tertiarySystemGroupedBackground, .separator, .opaqueSeparator, .link, .darkText, .lightText, .systemBlue, systemBrown, .systemGreen, .systemIndigo, .systemOrange, .systemPink, .systemPurple, .systemRed, .systemTeal, .systemYellow, .systemGray, .systemGray2, .systemGray3, .systemGray4, .systemGray5, .systemGray6, .clear, .black, .blue, .brown, .cyan, .darkGray, .gray, .green, .lightGray, .magenta, .orange, .purple, .red, .white, .yellow].sorted(by: { $0.hue < $1.hue })
    }
}

/// Conformation to `Comparable` protocol
extension Color: @retroactive Comparable {
	public static func < (lhs: Color, rhs: Color) -> Bool {
        return lhs.hue < rhs.hue
    }
}

/// More color sets.
public extension Color {
    static var rainbow: [Color] {
        return [.red, .orange, .yellow, .green, .blue, .cyan, .systemRed, .systemOrange, .systemYellow, .systemIndigo, .purple, .systemPink, .magenta, .systemGreen, .systemBlue, .systemCyan, .systemMint, .systemPurple, .systemTeal].sorted(by: { $0.hue < $1.hue })
    }

    static var systemColors: [Color] {
        return [.systemRed, .systemMint, .systemCyan, .systemBlue, .systemGray, .systemBrown, .systemGreen, .systemPurple, .systemIndigo, .systemYellow, .systemOrange, .systemPink, .systemTeal, .systemBrown, .systemPurple].sorted(by: { $0.hue < $1.hue })
    }

    static var labelColors: [Color] {
        return [.label, .secondaryLabel, .tertiaryLabel, .quaternaryLabel]
    }

    static var fillColors: [Color] {
        return [.systemFill, .secondarySystemFill, .tertiarySystemFill, .quaternarySystemFill]
    }

    static var standardContentBackgroundColors: [Color] {
        return [.systemBackground, .secondarySystemBackground, .tertiarySystemBackground]
    }

    static var groupedContentBackgroundColors: [Color] {
        return [.systemGroupedBackground, .secondarySystemGroupedBackground, .tertiarySystemGroupedBackground]
    }

    static var separatorColors: [Color] {
        return [.separator, .opaqueSeparator]
    }

    static var nonadaptableColors: [Color] {
        return [.darkText, .lightText]
    }

    static var adaptableColors: [Color] {
        return [.systemBlue, .systemBrown, .systemGreen, .systemIndigo, .systemOrange, .systemPink, .systemPurple, .systemRed, .systemTeal, .systemYellow]
    }

    static var adaptableGrayColors: [Color] {
        return [.systemGray, .systemGray2, .systemGray3, .systemGray4, .systemGray5, .systemGray6]
    }

    static var fixedColors: [Color] {
        return [.black, .blue, .brown, .cyan, .darkGray, .gray, .green, .lightGray, .magenta, .orange, .purple, .red, .white, .yellow]
    }
}
