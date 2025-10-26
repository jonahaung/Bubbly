//
//  View+Mask.swift
//  XUI
//
//  Created by Aung Ko Min on 27/9/25.
//

import Swift
import SwiftUI

extension View {
    /// Masks this view using the alpha channel of the given view.
    @_disfavoredOverload
    @inlinable
    public func mask<T: View>(@ViewBuilder _ view: () -> T) -> some View {
        self.mask(view())
    }

    /// Masks the given view using the alpha channel of this view.
    @inlinable
    public func masking<T: View>(_ view: T) -> some View {
        hidden().background(view.mask(self))
    }

    /// Masks the given view using the alpha channel of this view.
    @inlinable
    public func masking<T: View>(@ViewBuilder _ view: () -> T) -> some View {
        masking(view())
    }

    /// https://www.fivestars.blog/articles/reverse-masks-how-to/
    @inlinable
    public func reverseMask<Mask: View>(
        alignment: Alignment = .center,
        @ViewBuilder _ mask: () -> Mask
    ) -> some View {
        self.mask(
            Rectangle()
                .overlay(mask().blendMode(.destinationOut), alignment: alignment)
        )
    }
}
extension Shape {
	public func fill<S: ShapeStyle>(
		_ fillContent: S,
		stroke strokeStyle: StrokeStyle,
		strokeColor: Color
	) -> some View {
		ZStack {
			fill(fillContent)
			stroke(strokeColor, style: strokeStyle)
		}
	}

	public func fillAndStrokeBorder<S: ShapeStyle>(
		_ fillContent: S,
		borderColor: Color,
		borderWidth: CGFloat,
		antialiased: Bool = true
	) -> some View where Self: InsettableShape {
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
