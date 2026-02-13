import SFSafeSymbols
import SwiftUI

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
					.symbolVariant(.fill)
			case .gray:
				SystemImage(icon, 20 * scale)
					.padding(2 * scale)
					.foregroundStyle(Color.gray.gradient)
					.symbolVariant(.fill)
			case let .color(color):
				SystemImage(icon, 20 * scale)
					.padding(2 * scale)
					.foregroundStyle(color.gradient)
					.symbolVariant(.fill)
			case .randomColor:
				SystemImage(icon, 20 * scale)
					.padding(2 * scale)
					.foregroundStyle(icon.rawValue.color.gradient)
					.symbolVariant(.fill)
			}
		case let .square(bgStyle):
			switch bgStyle {
			case .plain:
				SystemImage(icon, 15 * scale)
					.padding(6 * scale)
					.background {
						Color(uiColor: .systemFill)
							.clipShape(.containerRelative)
					}
					.containerShape(RoundedRectangle(cornerRadius: 8 * scale))
					.compositingGroup()
					.symbolVariant(.fill)
			case .gray:
				SystemImage(icon, 15 * scale)
					.foregroundStyle(Color(uiColor: .systemBackground).gradient)
					.padding(6 * scale)
					.background {
						Color.gray
							.clipShape(.containerRelative)
					}
					.containerShape(RoundedRectangle(cornerRadius: 8 * scale))
					.compositingGroup()
					.symbolVariant(.fill)
			case let .color(color):
				SystemImage(icon, 15 * scale)
					.foregroundStyle(Color(uiColor: .systemBackground).gradient)
					.padding(6 * scale)
					.background {
						color
							.clipShape(.containerRelative)
					}
					.containerShape(RoundedRectangle(cornerRadius: 8 * scale))
					.compositingGroup()
					.symbolVariant(.fill)
			case .randomColor:
				SystemImage(icon, 15 * scale)
					.foregroundStyle(Color(uiColor: .systemBackground).gradient)
					.padding(6 * scale)
					.background {
						icon.rawValue.color
							.clipShape(.containerRelative)
					}
					.containerShape(RoundedRectangle(cornerRadius: 8 * scale))
					.compositingGroup()
					.symbolVariant(.fill)
			}
		case let .circle(bgStyle):
			switch bgStyle {
			case .plain:
				SystemImage(icon, 15 * scale)
					.padding(6 * scale)
					.background {
						Color(uiColor: .systemFill)
							.clipShape(.containerRelative)
					}
					.containerShape(Circle())
					.compositingGroup()
					.symbolVariant(.fill)
			case .gray:
				SystemImage(icon, 15 * scale)
					.foregroundStyle(Color(uiColor: .systemBackground).gradient)
					.padding(6 * scale)
					.background {
						Color.gray
							.clipShape(.containerRelative)
					}
					.containerShape(Circle())
					.compositingGroup()
					.symbolVariant(.fill)
			case let .color(color):
				SystemImage(icon, 15 * scale)
					.foregroundStyle(Color(uiColor: .systemBackground).gradient)
					.padding(6 * scale)
					.background {
						color
							.clipShape(.containerRelative)
					}
					.containerShape(Circle())
					.compositingGroup()
					.symbolVariant(.fill)
			case .randomColor:
				SystemImage(icon, 15 * scale)
					.foregroundStyle(Color(uiColor: .systemBackground).gradient)
					.padding(6 * scale)
					.background {
						icon.rawValue.color
							.clipShape(.containerRelative)
					}
					.containerShape(Circle())
					.compositingGroup()
					.symbolVariant(.fill)
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
