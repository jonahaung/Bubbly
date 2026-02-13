import SwiftUI
import XUI

public enum BubbleColor: String, Sendable, Hashable, CaseIterable, Codable, Identifiable,
	CaseNameReflectable
{
	case `default`
	case skyBlue, babyPink
	case mistyRose, paleTurquoise, mintCream, warmBeige
	case lilac, blush, lemon, mint, periwinkle
	case peach, coral, sand, teal

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

private enum Palette {
	// MARK: - Basics

	static let defaultGreen =
		Color(red: 0.85, green: 1.0, blue: 0.85)

	// MARK: - Blues

	static let skyBlue =
		Color(red: 0.81, green: 0.90, blue: 0.95)

	static let periwinkle =
		Color(red: 0.85, green: 0.90, blue: 0.96)

	static let teal =
		Color(red: 0.60, green: 0.85, blue: 0.85)

	// MARK: - Greens

	static let mint =
		Color(red: 0.80, green: 0.96, blue: 0.88)

	static let mintCream =
		Color(red: 0.88, green: 0.94, blue: 0.85)

	static let paleTurquoise =
		Color(red: 0.87, green: 0.99, blue: 1.0)

	// MARK: - Purples / Lilacs

	static let lilac =
		Color(red: 0.90, green: 0.88, blue: 0.96)

	// MARK: - Reds / Pinks

	static let babyPink =
		Color(red: 1.0, green: 0.86, blue: 0.90)

	static let blush =
		Color(red: 0.99, green: 0.88, blue: 0.89)

	static let mistyRose =
		Color(red: 1.0, green: 0.89, blue: 0.88)

	static let coral =
		Color(red: 1.0, green: 0.78, blue: 0.75)

	static let peach =
		Color(red: 1.0, green: 0.90, blue: 0.80)

	// MARK: - Yellows / Beiges

	static let lemon =
		Color(red: 0.99, green: 0.96, blue: 0.87)

	static let warmBeige =
		Color(red: 0.98, green: 0.88, blue: 0.79)

	static let sand =
		Color(red: 0.96, green: 0.91, blue: 0.78)
}

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
