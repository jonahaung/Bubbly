//
//  AnimatedGradient.swift
//  XUI
//
//  Created by Aung Ko Min on 9/2/26.
//

import SwiftUI

public struct AnimatedGradient: View {
	private let colors: [Color]
	public init(colors: [Color] = [
		.purple, .indigo, .purple, .yellow,
		.pink, .purple, .pink, .yellow,
		.orange, .pink, .yellow, .orange,
		.yellow, .orange, .pink, .purple,
	]) {
		self.colors = colors
	}

	public var body: some View {
		TimelineView(.animation) { context in
			let time = context.date.timeIntervalSince1970
			let offsetX = Float(sin(time)) * 0.1
			let offsetY = Float(cos(time)) * 0.1

			MeshGradient(
				width: 4,
				height: 4,
				points: [
					[0.0, 0.0],
					[0.3, 0.0],
					[0.7, 0.0],
					[1.0, 0.0],
					[0.0, 0.3],
					[0.2 + offsetX, 0.4 + offsetY],
					[0.7 + offsetX, 0.2 + offsetY],
					[1.0, 0.3],
					[0.0, 0.7],
					[0.3 + offsetX, 0.8],
					[0.7 + offsetX, 0.6],
					[1.0, 0.7],
					[0.0, 1.0],
					[0.3, 1.0],
					[0.7, 1.0],
					[1.0, 1.0],
				],
				colors: colors
			)
		}
	}
}
