//
//  QuakeRenderer.swift
//  XUI
//
//  Created by Aung Ko Min on 10/10/25.
//

import SwiftUI

public struct QuakeRenderer: TextRenderer {
	
	var moveAmount: Double
	public var animatableData: Double {
		get { moveAmount }
		set { moveAmount = newValue }
	}

	public init(moveAmount: Double) {
		self.moveAmount = moveAmount
	}

	public func draw(layout: Text.Layout, in context: inout GraphicsContext) {
		for line in layout {
			for run in line {
				for glyph in run {
					var copy = context
					let yOffset = Double.random(in: -moveAmount...moveAmount)
					copy.translateBy(x: yOffset, y: 0)
					copy.draw(glyph, options: .disablesSubpixelQuantization)
				}
			}
		}
	}
}
