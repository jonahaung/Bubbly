//
//  SoftShadow.swift
//  XUI
//
//  Created by Aung Ko Min on 12/9/25.
//

import SwiftUI
enum ShadowConstants {
	/// Additional blur applied to shadows to enhance their natural appearance
	static let additionalBlur: CGFloat = 2
}
public struct SoftShadow: ViewModifier {
    private let color: Color
    private let radius: CGFloat
    private let opacity: Double
    private let xOffset: CGFloat
    private let yOffset: CGFloat

    /// Creates a new soft shadow modifier.
    /// - Parameters:
    ///   - color: The color of the shadow.
    ///   - radius: The blur radius of the shadow.
    ///   - opacity: The opacity of the shadow (0.0-1.0).
    ///   - xOffset: Horizontal offset of the shadow.
    ///   - yOffset: Vertical offset of the shadow.
    public init(
        color: Color = .black,
        radius: CGFloat = 8,
        opacity: Double = 0.25,
        xOffset: CGFloat = 0,
        yOffset: CGFloat = 0
    ) {
        self.color = color
        self.radius = radius
        self.opacity = opacity
        self.xOffset = xOffset
        self.yOffset = yOffset
    }

    /// Calculates the dynamic radius based on offset magnitude.
    /// - Parameter baseRadius: The base radius to adjust.
    /// - Returns: An adjusted radius that takes into account the shadow's offset.
    private func dynamicRadius(_ baseRadius: CGFloat) -> CGFloat {
        let offsetMagnitude = sqrt(pow(xOffset, 2) + pow(yOffset, 2))
        let radiusMultiplier = max(1.0, 1.0 + (offsetMagnitude / 32) * 0.5)
        return baseRadius * radiusMultiplier
    }

    public func body(content: Content) -> some View {
        content
            // Layer 1: Tight shadow
            .modifier(InnerShadowLayer(
                content: content,
                color: color,
                radius: dynamicRadius(radius / 16),
                opacity: opacity,
                xOffset: xOffset / 16,
                yOffset: yOffset / 16
            ))
            // Layer 2: Medium shadow
            .modifier(InnerShadowLayer(
                content: content,
                color: color,
                radius: dynamicRadius(radius / 8),
                opacity: opacity,
                xOffset: xOffset / 8,
                yOffset: yOffset / 8
            ))
            // Layer 3: Wide shadow
            .modifier(InnerShadowLayer(
                content: content,
                color: color,
                radius: dynamicRadius(radius / 4),
                opacity: opacity,
                xOffset: xOffset / 4,
                yOffset: yOffset / 4
            ))
            // Layer 4: Broader shadow
            .modifier(InnerShadowLayer(
                content: content,
                color: color,
                radius: dynamicRadius(radius / 2),
                opacity: opacity,
                xOffset: xOffset / 2,
                yOffset: yOffset / 2
            ))
            // Layer 5: Broadest shadow
            .modifier(InnerShadowLayer(
                content: content,
                color: color,
                radius: dynamicRadius(radius),
                opacity: opacity,
                xOffset: xOffset,
                yOffset: yOffset
            ))
    }

    /// A single layer of the soft shadow effect.
    private struct InnerShadowLayer: ViewModifier {
        let content: Any
        let color: Color
        let radius: CGFloat
        let opacity: Double
        let xOffset: CGFloat
        let yOffset: CGFloat
        
        private let additionalBlur: CGFloat = 2
        
        /// Calculates the final y-offset including dynamic adjustments.
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
import SwiftUI

public extension View {
	/// Applies a realistic, multi-layered shadow effect that provides better depth perception than SwiftUI's native shadow.
	///
	/// The soft shadow effect is created by combining multiple shadow layers with different intensities and offsets,
	/// resulting in a more natural-looking shadow that better simulates real-world lighting.
	///
	/// ```swift
	/// Text("Hello World")
	///     .proShadow(
	///         color: .black,
	///         radius: 8,
	///         opacity: 0.25,
	///         x: 0,
	///         y: 4
	///     )
	/// ```
	///
	/// - Parameters:
	///   - color: The color of the shadow. Defaults to black.
	///   - radius: The blur radius of the shadow. Larger values create softer shadows. Defaults to 0.
	///   - opacity: The opacity of the shadow, ranging from 0 to 1. Defaults to 0.25.
	///   - x: The horizontal offset of the shadow. Positive values move right, negative left. Defaults to 0.
	///   - y: The vertical offset of the shadow. Positive values move down, negative up. Defaults to 0.
	/// - Returns: A view with the soft shadow effect applied.
	func proShadow(
		color: Color = .black,
		radius: CGFloat = 0,
		opacity: CGFloat = 0.2,
		x: CGFloat = 0,
		y: CGFloat = 0
	) -> some View {
		let validatedRadius = max(0, radius)
		return modifier(
			SoftShadow(
				color: color,
				radius: validatedRadius,
				opacity: opacity,
				xOffset: x,
				yOffset: y
			)
		)
	}

	/// Applies a soft shadow effect based on Material Design elevation principles.
	///
	/// This modifier automatically calculates appropriate shadow properties based on the elevation value,
	/// following Material Design guidelines for creating consistent shadow hierarchies.
	///
	/// ```swift
	/// VStack {
	///     Text("Card 1").proShadow(elevation: 2)
	///     Text("Card 2").proShadow(elevation: 8)
	/// }
	/// ```
	///
	/// - Parameters:
	///   - color: The shadow color. Defaults to black.
	///   - elevation: The height of the surface in points. Higher values create larger shadows. Defaults to 4.
	///   - opacity: The shadow opacity, ranging from 0 to 1. Defaults to 0.25.
	///   - x: Additional horizontal offset. Defaults to 0.
	///   - y: Additional vertical offset. Defaults to 0.
	/// - Returns: A view with elevation-based shadow applied.
	func proShadow(
		color: Color = .black,
		elevation: CGFloat = 4,
		opacity: CGFloat = 0.25,
		x: CGFloat = 0,
		y: CGFloat = 0
	) -> some View {
		modifier(
			SoftShadow(
				color: color,
				radius: elevation,
				opacity: opacity,
				xOffset: x == 0 ? 0 : x + (elevation / 2),
				yOffset: y == 0 ? 0 : y + (elevation / 2)
			)
		)
	}
}
