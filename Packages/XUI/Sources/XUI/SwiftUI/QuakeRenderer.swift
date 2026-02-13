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
		if moveAmount != 0 {
			for line in layout {
				for run in line {
					for glyph in run {
						var copy = context
						let yOffset = Double.random(in: -moveAmount ... moveAmount)
						copy.translateBy(x: 0, y: yOffset)
						copy.draw(glyph, options: .disablesSubpixelQuantization)
					}
				}
			}
		} else {
			for line in layout {
				for run in line {
					for glyph in run {
//						var copy = context
//						let yOffset = Double.random(in: -moveAmount ... moveAmount)
//						copy.translateBy(x: 0, y: yOffset)
						context.draw(glyph, options: .disablesSubpixelQuantization)
					}
				}
			}
		}
	}
}

public struct ColorfulRender: TextRenderer {
	public init() {}
	public func draw(layout: Text.Layout, in context: inout GraphicsContext) {
		// Iterate through RunSlice and their indices
		for (index, slice) in layout.flattenedRunSlices.enumerated() {
			// Calculate the angle of color adjustment based on the index
			let degree = Angle.degrees(360 / Double(index + 1))
			// Create a copy of GraphicsContext
			var copy = context
			// Apply hue rotation filter
			copy.addFilter(.hueRotation(degree))
			// Draw the current Slice in the context
			copy.draw(slice)
		}
	}
}

extension Text.Layout {
	var flattenedRuns: some RandomAccessCollection<Text.Layout.Run> {
		flatMap { line in
			line
		}
	}
}

extension Text.Layout {
	var flattenedRunSlices: some RandomAccessCollection<Text.Layout.RunSlice> {
		flattenedRuns.flatMap(\.self)
	}
}
