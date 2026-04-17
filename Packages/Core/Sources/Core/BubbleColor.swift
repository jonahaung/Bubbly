// © 2026 Aung Ko Min

import SwiftUI
import XUI

// MARK: - BubbleColor

public enum BubbleColor: String, Sendable, Hashable, CaseIterable, Codable, Identifiable, CaseNameReflectable {
	case green, blue, cyan, pink, purple, yellow, gray

	public var id: String {
		rawValue
	}
	public var value: Color {
		Color("bubble_\(rawValue)", bundle: .module)
	}
}

// MARK: - Palette

private enum Palette {
	// MARK: - Basics

	static let defaultGreen: Color = .init("bubble_green", bundle: .module)
	static let skyBlue: Color = .init("bubble_blue", bundle: .module)

	static let paleTurquoise: Color = .init("bubble_cyan", bundle: .module)

	// MARK: - Purples / Lilacs

	static let lilac: Color = .init("bubble_purple", bundle: .module)

	// MARK: - Reds / Pinks

	static let babyPink: Color = .init("bubble_pink", bundle: .module)

	static let lemon: Color = .init("bubble_yellow", bundle: .module)
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
		.green
	}
	public static let `default` = BubbleColor.green
}
