//  APCAColor.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

@available(iOS 26.0, *)
private struct MinimumContrastColorFont<Foreground: ShapeStyle, Background: ShapeStyle>: ShapeStyle where Foreground.Resolved == Color.Resolved, Background.Resolved == Color.Resolved {
    var foreground: Foreground

    var background: Background

    func resolve(in environment: EnvironmentValues) -> Color {
        let t = foreground.resolve(in: environment)
        let b = background.resolve(in: environment)

        let targetColor = t.apcaLuminance > b.apcaLuminance ? Color.white : .black

        let font = (environment.font ?? Font.default).resolve(in: environment.fontResolutionContext)
        let pointSize = font.pointSize
        let weight = font.weight

        let target = Font.APCAContrastTarget(for: pointSize, weight: weight)

        return stride(from: 0, to: 1, by: 0.05)
            .lazy
            .map { fraction in
                Color(t).mix(with: targetColor, by: fraction)
            }
            .first { candidate in
                let candidate = candidate.resolve(in: environment)

                return abs(Color.Resolved.APCAContrast(text: candidate, background: b)) >= abs(target)
            } ?? targetColor
    }
}

@available(iOS 18.0, *)
private struct MinimumContrastColor<Foreground: ShapeStyle, Background: ShapeStyle>: ShapeStyle where Foreground.Resolved == Color.Resolved, Background.Resolved == Color.Resolved {
    var foreground: Foreground

    var background: Background

    var minimumContrast: Float

    func resolve(in environment: EnvironmentValues) -> Color {
        let t = foreground.resolve(in: environment)
        let b = background.resolve(in: environment)

        let targetColor = t.apcaLuminance > b.apcaLuminance ? Color.white : .black

        return stride(from: 0, to: 1, by: 0.05)
            .lazy
            .map { fraction in
                Color(t).mix(with: targetColor, by: fraction)
            }
            .first { candidate in
                let candidate = candidate.resolve(in: environment)

                return abs(Color.Resolved.APCAContrast(text: candidate, background: b)) >= abs(minimumContrast)
            } ?? targetColor
    }
}

public extension ShapeStyle where Resolved == Color.Resolved {
    @available(iOS 18.0, *)
    func minimumContrast<Background: ShapeStyle>(_ contrast: Float, over background: Background) -> some ShapeStyle where Background.Resolved == Color.Resolved {
        MinimumContrastColor(foreground: self, background: background, minimumContrast: contrast)
    }

    @available(iOS 26.0, *)
    func minimumContrast<Background: ShapeStyle>(over background: Background) -> some ShapeStyle where Background.Resolved == Color.Resolved {
        MinimumContrastColorFont(foreground: self, background: background)
    }
}

@available(iOS 18.0, *)
public struct APCADerivedForegroundColor: ViewModifier {
    @ScaledMetric var fontSize: CGFloat

    var weight: Font.Weight

    var foreground: Color

    var background: Color

    @Environment(\.self) var environment

    public init(foregroundColor: Color, backgroundColor: Color, fontSize: CGFloat, relativeTo textStyle: Font.TextStyle = .body, weight: Font.Weight = .regular) {
        foreground = foregroundColor
        background = backgroundColor
        _fontSize = .init(wrappedValue: fontSize, relativeTo: textStyle)
        self.weight = weight
    }

    public func body(content: Content) -> some View {
        let contrast = Font.APCAContrastTarget(for: fontSize, weight: weight)

        content.foregroundStyle(foreground.minimumContrast(contrast, over: background))
    }
}

public extension View {
    @available(iOS 18.0, *)
    func apcaForeground(
        _ foreground: Color,
        over background: Color,
        fontSize: CGFloat,
        relativeTo textStyle: Font.TextStyle = .body,
        weight: Font.Weight = .regular
    ) -> some View {
        modifier(
            APCADerivedForegroundColor(
                foregroundColor: foreground,
                backgroundColor: background,
                fontSize: fontSize,
                relativeTo: textStyle,
                weight: weight
            )
        )
    }

    @available(iOS 26.0, *)
    func apcaForeground<Foreground: ShapeStyle, Background: ShapeStyle>(
        _ foreground: Foreground,
        over background: Background
    ) -> some View where Foreground.Resolved == Color.Resolved, Background.Resolved == Color.Resolved {
        foregroundStyle(foreground.minimumContrast(over: background))
    }
}

public extension Color.Resolved {
    static func APCAContrast(text: Color.Resolved, background: Color.Resolved) -> Float {
        let text = text.over(background)

        func softClamp(_ luminance: Float) -> Float {
            guard luminance < 0.022 else { return luminance }

            return pow(0.022 - luminance, 1.414) + luminance
        }

        var Ybackground = softClamp(background.apcaLuminance)
        var Ytext = softClamp(text.apcaLuminance)

        if Ybackground > Ytext {
            Ybackground = pow(Ybackground, 0.56)
            Ytext = pow(Ytext, 0.57)
        } else {
            Ybackground = pow(Ybackground, 0.65)
            Ytext = pow(Ytext, 0.62)
        }

        let contrast = (Ybackground - Ytext) * 1.14

        if abs(contrast) < 0.1 {
            return 0
        } else if contrast > 0 {
            return 100 * (contrast - 0.027)
        } else {
            return 100 * (contrast + 0.027)
        }
    }

    static func over(a: Self, b: Self) -> Self {
        let i = (1 - a.opacity)

        let opacity = a.opacity + b.opacity * i

        return .init(
            red: (a.red * a.opacity + b.red * b.opacity * i) / opacity,
            green: (a.green * a.opacity + b.green * b.opacity * i) / opacity,
            blue: (a.blue * a.opacity + b.blue * b.opacity * i) / opacity,
            opacity: opacity
        )
    }

    var apcaLuminance: Float {
        pow(red, 2.4) * 0.2126729 +
            pow(green, 2.4) * 0.7151522 +
            pow(blue, 2.4) * 0.0721750
    }

    func over(_ background: Color.Resolved) -> Color.Resolved {
        .over(a: self, b: background)
    }
}
