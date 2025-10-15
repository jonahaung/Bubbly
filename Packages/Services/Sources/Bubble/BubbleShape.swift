//
//  BubbleShape.swift
//  Services
//
//  Created by Aung Ko Min on 1/10/25.
//

import SwiftUI

public struct BubbleShape: Shape {
	let corner: BubbleCorner
	let cornerRadius: CGFloat

	public init(corner: BubbleCorner, cornerRadius: CGFloat) {
		self.corner = corner
		self.cornerRadius = cornerRadius
	}

	public func path(in rect: CGRect) -> Path {
		let bezier = UIBezierPath(
			roundedRect: rect,
			byRoundingCorners: corner.uiRectCorner,
			cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
		)
		return Path(bezier.cgPath)
	}
}
