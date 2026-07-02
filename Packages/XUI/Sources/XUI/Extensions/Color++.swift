//  Color++.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public extension Color {
    func lighter(byPercentage percentage: CGFloat) -> Color {
        adjusted(byPercentage: abs(percentage))
    }

    func darker(byPercentage percentage: CGFloat) -> Color {
        adjusted(byPercentage: abs(percentage) * -1)
    }

    func adjusted(byPercentage percentage: CGFloat) -> Color {
        Color(UXColor(self).adjusted(byPercentage: percentage))
    }
}

#if canImport(UIKit)

    import UIKit

    public typealias UXColor = UIColor

#elseif canImport(AppKit)

    import AppKit

    public typealias UXColor = NSColor

#endif

public extension UXColor {
    func lighter(byPercentage percentage: CGFloat) -> Self {
        adjusted(byPercentage: abs(percentage))
    }

    func darker(byPercentage percentage: CGFloat) -> Self {
        adjusted(byPercentage: abs(percentage) * -1)
    }

    func adjusted(byPercentage percentage: CGFloat) -> Self {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return .init(
            red: min(red + percentage / 100, 1.0),
            green: min(green + percentage / 100, 1.0),
            blue: min(blue + percentage / 100, 1.0),
            alpha: alpha
        )
    }
}
