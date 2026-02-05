//
//  LoadingIndicator.swift
//  BmCamera
//
//  Created by Aung Ko Min on 28/3/21.
//

import SwiftUI

public struct LoadingIndicator: View {
	private let size: CGFloat
	public init(_ size: CGFloat) {
		self.size = size
	}
	public var body: some View {
		TimelineView(.animation) { context in
			let angle = context.date.timeIntervalSinceReferenceDate * 360
			Circle()
				.trim(from: 0.2, to: 1)
				.stroke(
					AngularGradient(
						gradient: Gradient(colors: [.blue, .indigo, .red]),
						center: .center
					),
					style: StrokeStyle(lineWidth: 2, lineCap: .round)
				)
				.rotationEffect(.degrees(angle))
		}.frame(square: size)
	}
}
