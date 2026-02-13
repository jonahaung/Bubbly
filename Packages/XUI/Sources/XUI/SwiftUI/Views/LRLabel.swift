import SFSafeSymbols
import SwiftUI

public struct LRLabel<Left: View, Right: View>: View {
	private let spacing: CGFloat
	private var left: () -> Left
	private var right: () -> Right

	public init(spacing: CGFloat = 5,
	            @ViewBuilder left: @escaping () -> Left,
	            @ViewBuilder right: @escaping () -> Right)
	{
		self.spacing = spacing
		self.left = left
		self.right = right
	}

	public var body: some View {
		HStack(spacing: spacing) {
			left()
			right()
		}
	}
}

public struct LRIconLabel: View {
	private let spacing: CGFloat
	private var icon: String
	private var title: String

	public init(_ icon: String, _ title: String, spacing: CGFloat = 2) {
		self.spacing = spacing
		self.icon = icon
		self.title = title
	}

	public init(symbol: SFSafeSymbols.SFSymbol, _ title: String, spacing: CGFloat = 2) {
		self.init(symbol.rawValue, title, spacing: spacing)
	}

	public var body: some View {
		LRLabel(spacing: spacing) {
			SystemImage(systemName: icon)
		} right: {
			Text(.init(title))
		}
	}
}
