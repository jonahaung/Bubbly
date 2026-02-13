import SwiftUI

enum ShadowConstants {
	static let additionalBlur: CGFloat = 2
}

public struct SoftShadow: ViewModifier {
	private let color: Color
	private let radius: CGFloat
	private let opacity: Double
	private let xOffset: CGFloat
	private let yOffset: CGFloat

	public init(color: Color = .black,
	            radius: CGFloat = 8,
	            opacity: Double = 0.25,
	            xOffset: CGFloat = 0,
	            yOffset: CGFloat = 0)
	{
		self.color = color
		self.radius = radius
		self.opacity = opacity
		self.xOffset = xOffset
		self.yOffset = yOffset
	}

	private func dynamicRadius(_ baseRadius: CGFloat) -> CGFloat {
		let offsetMagnitude = sqrt(pow(xOffset, 2) + pow(yOffset, 2))
		let radiusMultiplier = max(1.0, 1.0 + (offsetMagnitude / 32) * 0.5)
		return baseRadius * radiusMultiplier
	}

	public func body(content: Content) -> some View {
		content
			.modifier(InnerShadowLayer(
				color: color,
				radius: dynamicRadius(radius / 16),
				opacity: opacity,
				xOffset: xOffset / 16,
				yOffset: yOffset / 16
			))
			.modifier(InnerShadowLayer(
				color: color,
				radius: dynamicRadius(radius / 8),
				opacity: opacity,
				xOffset: xOffset / 8,
				yOffset: yOffset / 8
			))
			.modifier(InnerShadowLayer(
				color: color,
				radius: dynamicRadius(radius / 4),
				opacity: opacity,
				xOffset: xOffset / 4,
				yOffset: yOffset / 4
			))
			.modifier(InnerShadowLayer(
				color: color,
				radius: dynamicRadius(radius / 2),
				opacity: opacity,
				xOffset: xOffset / 2,
				yOffset: yOffset / 2
			))
			.modifier(InnerShadowLayer(
				color: color,
				radius: dynamicRadius(radius),
				opacity: opacity,
				xOffset: xOffset,
				yOffset: yOffset
			))
	}

	private struct InnerShadowLayer: ViewModifier {
		let color: Color
		let radius: CGFloat
		let opacity: Double
		let xOffset: CGFloat
		let yOffset: CGFloat

		private var calculatedYOffset: CGFloat {
			yOffset + ((yOffset >= 0 ? 1 : -1) * radius) + ShadowConstants.additionalBlur
		}

		func body(content: Content) -> some View {
			content
				.shadow(
					color: color.opacity(opacity),
					radius: radius + ShadowConstants.additionalBlur,
					x: xOffset,
					y: calculatedYOffset
				)
		}
	}
}

public extension View {
	func proShadow(color: Color = .black,
	               radius: CGFloat = 0,
	               opacity: CGFloat = 0.2,
	               xOffset: CGFloat = 0,
	               yOffset: CGFloat = 0) -> some View
	{
		let validatedRadius = max(0, radius)
		return modifier(
			SoftShadow(
				color: color,
				radius: validatedRadius,
				opacity: opacity,
				xOffset: xOffset,
				yOffset: yOffset
			)
		)
	}

	func proShadow(color: Color = .black,
	               elevation: CGFloat = 4,
	               opacity: CGFloat = 0.25,
	               xOffset: CGFloat = 0,
	               yOffset: CGFloat = 0) -> some View
	{
		modifier(
			SoftShadow(
				color: color,
				radius: elevation,
				opacity: opacity,
				xOffset: xOffset == 0 ? 0 : xOffset + (elevation / 2),
				yOffset: yOffset == 0 ? 0 : yOffset + (elevation / 2)
			)
		)
	}
}
