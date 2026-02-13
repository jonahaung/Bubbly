import SwiftUI

@MainActor
@Animatable
public struct ScreenOutModifier: ViewModifier {
	public let edge: Edge
	public var progress: Double

	@AnimatableIgnored
	@State private var rect: CGRect = .zero

	@AnimatableIgnored
	@State private var canvasSize: CGSize = .zero

	// MARK: - Init

	public init(edge: Edge, progress: Double) {
		self.edge = edge
		self.progress = progress
	}

	// MARK: - Body

	public func body(content: Content) -> some View {
		content
			.transformEffect(calculateAffineTransform())
			.overlay {
				Color.clear
					.onGeometryChange(for: CGRect.self) { proxy in
						proxy.frame(in: .global)
					} action: { newValue in
						rect = newValue
						canvasSize = newValue.size
					}
			}
	}

	// MARK: - Transform

	private func calculateAffineTransform() -> CGAffineTransform {
		let target = switch edge {
		case .leading:
			CGPoint(x: -rect.maxX, y: 0)
		case .trailing:
			CGPoint(x: canvasSize.width, y: 0)
		case .top:
			CGPoint(x: 0, y: -rect.maxY)
		case .bottom:
			CGPoint(x: 0, y: canvasSize.height)
		}

		return CGAffineTransform(
			translationX: target.x * progress,
			y: target.y * progress
		)
	}
}

public extension AnyTransition {
	@MainActor static func screenOut(edge: Edge) -> AnyTransition {
		.modifier(
			active: ScreenOutModifier(edge: edge, progress: 1),
			identity: ScreenOutModifier(edge: edge, progress: 0)
		)
	}
}
