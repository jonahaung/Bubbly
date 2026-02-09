//
//  EarthquakeRenderer.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 30/1/26.
//

import SwiftUI

struct EarthquakeAttribute: TextAttribute {}

struct EarthquakeRenderer: TextRenderer {
	var moveAmount: Double
	var shouldBlur = false

	var animatableData: Double {
		get { moveAmount }
		set { moveAmount = newValue }
	}

	func draw(layout: Text.Layout, in context: inout GraphicsContext) {
		for line in layout {
			for run in line {
				for glyph in run {
					if run[EarthquakeAttribute.self] != nil {
						let yOffset = Double.random(in: -moveAmount ... moveAmount)
						var copy = context

						if shouldBlur {
							copy.addFilter(.blur(radius: moveAmount / 4))
						}

						copy.translateBy(x: 0, y: yOffset)
						copy.draw(glyph)
					} else {
						context.draw(glyph)
					}
				}
			}
		}
	}
}
