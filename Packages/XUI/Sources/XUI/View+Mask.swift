import Swift
import SwiftUI

public extension View {
	/// Masks this view using the alpha channel of the given view.
	@_disfavoredOverload
	@inlinable
	func mask(@ViewBuilder _ view: () -> some View) -> some View {
		mask(view())
	}

	/// Masks the given view using the alpha channel of this view.
	@inlinable
	func masking(_ view: some View) -> some View {
		hidden().background(view.mask(self))
	}

	/// Masks the given view using the alpha channel of this view.
	@inlinable
	func masking(@ViewBuilder _ view: () -> some View) -> some View {
		masking(view())
	}

	/// https://www.fivestars.blog/articles/reverse-masks-how-to/
	@inlinable
	func reverseMask(alignment: Alignment = .center,
	                 @ViewBuilder _ mask: () -> some View) -> some View
	{
		self.mask(
			Rectangle()
				.overlay(mask().blendMode(.destinationOut), alignment: alignment)
		)
	}
}

public extension Shape {
	func fill(_ fillContent: some ShapeStyle,
	          stroke strokeStyle: StrokeStyle,
	          strokeColor: Color) -> some View
	{
		ZStack {
			fill(fillContent)
			stroke(strokeColor, style: strokeStyle)
		}
	}

	func fillAndStrokeBorder(_ fillContent: some ShapeStyle,
	                         borderColor: Color,
	                         borderWidth: CGFloat,
	                         antialiased: Bool = true) -> some View where Self: InsettableShape
	{
		ZStack {
			self.inset(by: borderWidth / 2).fill(fillContent)
			self.strokeBorder(
				borderColor,
				lineWidth: borderWidth,
				antialiased: antialiased
			)
		}
		.compositingGroup()
	}
}
