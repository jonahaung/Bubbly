// © 2026 Aung Ko Min

import SwiftUI
import XUI

// MARK: - BubbleColor

public enum BubbleColor: String, Sendable, Hashable, CaseIterable, Codable, Identifiable,
    CaseNameReflectable
{
    case `default`
    case skyBlue
    case babyPink
    case mistyRose
    case paleTurquoise
    case mintCream
    case warmBeige
    case lilac
    case blush
    case lemon
    case mint
    case periwinkle
    case peach
    case coral
    case sand
    case teal

    public var id: String {
        rawValue
    }

    public var value: Color {
        switch self {
        case .default: Palette.defaultGreen
        case .skyBlue: Palette.skyBlue
        case .periwinkle: Palette.periwinkle
        case .teal: Palette.teal
        case .mint: Palette.mint
        case .mintCream: Palette.mintCream
        case .paleTurquoise: Palette.paleTurquoise
        case .lilac: Palette.lilac
        case .babyPink: Palette.babyPink
        case .blush: Palette.blush
        case .mistyRose: Palette.mistyRose
        case .coral: Palette.coral
        case .peach: Palette.peach
        case .lemon: Palette.lemon
        case .warmBeige: Palette.warmBeige
        case .sand: Palette.sand
        }
    }
}

extension Color {
    static func dynamic(light: Color, dark: Color) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

// MARK: - Palette

private enum Palette {
    // MARK: - Basics

    static let defaultGreen: Color = .dynamic(
        light: Color(red: 0.865, green: 1.0, blue: 0.865),
        dark: Color(red: 0.15, green: 0.35, blue: 0.20),
    )

    // MARK: - Blues

    static let skyBlue: Color = .dynamic(
        light: Color(red: 0.829, green: 0.91, blue: 0.955),
        dark: Color(red: 0.20, green: 0.30, blue: 0.40),
    )

    static let periwinkle: Color = .dynamic(
        light: Color(red: 0.865, green: 0.91, blue: 0.964),
        dark: Color(red: 0.25, green: 0.30, blue: 0.45),
    )

    static let teal: Color = .dynamic(
        light: Color(red: 0.64, green: 0.865, blue: 0.865),
        dark: Color(red: 0.15, green: 0.35, blue: 0.35),
    )

    // MARK: - Greens

    static let mint: Color = .dynamic(
        light: Color(red: 0.82, green: 0.964, blue: 0.892),
        dark: Color(red: 0.15, green: 0.40, blue: 0.30),
    )

    static let mintCream: Color = .dynamic(
        light: Color(red: 0.892, green: 0.946, blue: 0.865),
        dark: Color(red: 0.20, green: 0.35, blue: 0.25),
    )

    static let paleTurquoise: Color = .dynamic(
        light: Color(red: 0.883, green: 0.991, blue: 1.0),
        dark: Color(red: 0.20, green: 0.35, blue: 0.40),
    )

    // MARK: - Purples / Lilacs

    static let lilac: Color = .dynamic(
        light: Color(red: 0.91, green: 0.892, blue: 0.964),
        dark: Color(red: 0.30, green: 0.25, blue: 0.40),
    )

    // MARK: - Reds / Pinks

    static let babyPink: Color = .dynamic(
        light: Color(red: 1.0, green: 0.874, blue: 0.91),
        dark: Color(red: 0.40, green: 0.20, blue: 0.30),
    )

    static let blush: Color = .dynamic(
        light: Color(red: 0.991, green: 0.892, blue: 0.901),
        dark: Color(red: 0.35, green: 0.25, blue: 0.30),
    )

    static let mistyRose: Color = .dynamic(
        light: Color(red: 1.0, green: 0.901, blue: 0.892),
        dark: Color(red: 0.40, green: 0.25, blue: 0.25),
    )

    static let coral: Color = .dynamic(
        light: Color(red: 1.0, green: 0.802, blue: 0.775),
        dark: Color(red: 0.50, green: 0.30, blue: 0.25),
    )

    static let peach: Color = .dynamic(
        light: Color(red: 1.0, green: 0.91, blue: 0.82),
        dark: Color(red: 0.45, green: 0.30, blue: 0.20),
    )

    // MARK: - Yellows / Beiges

    static let lemon: Color = .dynamic(
        light: Color(red: 0.991, green: 0.964, blue: 0.883),
        dark: Color(red: 0.40, green: 0.40, blue: 0.20),
    )

    static let warmBeige: Color = .dynamic(
        light: Color(red: 0.982, green: 0.892, blue: 0.811),
        dark: Color(red: 0.40, green: 0.30, blue: 0.20),
    )

    static let sand: Color = .dynamic(
        light: Color(red: 0.964, green: 0.919, blue: 0.802),
        dark: Color(red: 0.35, green: 0.30, blue: 0.20),
    )
}

// MARK: - BubbleColor + XPickable, EmptyRepresentable

extension BubbleColor: XPickable, EmptyRepresentable {
    public var title: String {
        localizedName
    }

    @MainActor
    public var badge: (any RenderNode)? {
        Circle()
            .fill(value)
            .strokeBorder(Color.secondary, style: .init(lineWidth: 1))
            .frame(square: 25)
            .foregroundStyle(.primary)
            .opaqueView()
    }

    public static var empty: BubbleColor {
        .default
    }
}
