//
//  RandomShapeStyle.swift
//  XUI
//
//  Created by Aung Ko Min on 10/3/26.
//

import SwiftUI

public enum RandomShapeStyle {
	private static let colors = Color.adaptableColors
	public static func style(for string: String) -> some ShapeStyle {
		var rng = MinimalPCG(string: string)
		return colors[Int(rng.next()) % colors.count].gradient
	}
}

private struct MinimalPCG {
	var state: UInt64

	var inc: UInt64

	init(string: String) {
		self.state = string.utf8.reduce(0.0) { a, b in a + (Double(b) * .pi) }.bitPattern
		self.inc = (Double(string.count) * .pi).bitPattern
	}

	init(state: UInt64, inc: UInt64) {
		self.state = state
		self.inc = inc
	}

	mutating func next() -> UInt32 {
		let oldstate = state

		// Advance internal state
		state = oldstate &* 6364136223846793005 &+ (inc | 1)
		// Calculate output function (XSH RR), uses old state for max ILP
		let xorshifted = ((oldstate >> 18) ^ oldstate) >> 27
		let rot = Int(truncatingIfNeeded: oldstate >> 59)

		return UInt32(truncatingIfNeeded: (xorshifted >> rot) | (xorshifted << ((-rot) & 31)))
	}
}
