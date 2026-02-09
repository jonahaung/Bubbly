//
//  LoadingIndicator.swift
//  BmCamera
//
//  Created by Aung Ko Min on 28/3/21.
//

import SwiftUI

public struct LoadingIndicator: View {
	private let size: CGFloat
	private let lineWidth: CGFloat
	private let colors: [Color]
	private let progress: Double?

	public init(_ size: CGFloat,
	            lineWidth: CGFloat = 2,
	            colors: [Color] = [.white, .yellow, .orange, .red, .pink, .blue, .indigo],
	            progress: Double? = nil)
	{
		self.size = size
		self.lineWidth = lineWidth
		self.colors = colors
		self.progress = progress
	}

	public var body: some View {
		Group {
			if let progress {
				determinate(progress: progress)
			} else {
				indeterminate
			}
		}
		.frame(width: size, height: size)
	}

	private var indeterminate: some View {
		TimelineView(.animation) { context in
			let angle = context.date.timeIntervalSinceReferenceDate * 360
			Circle()
				.trim(from: 0.1, to: 1)
				.stroke(
					AngularGradient(
						gradient: Gradient(colors: colors),
						center: .center
					),
					style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
				)

				.rotationEffect(.degrees(angle))
		}
		.transition(.scale(0.01, anchor: .center).animation(.bouncy))
	}

	private func determinate(progress: Double) -> some View {
		let clamped = min(max(progress, 0), 1)
		return ZStack {
			Circle()
				.stroke(
					Color.primary.opacity(0.12),
					style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
				)
			Circle()
				.trim(from: 0, to: clamped)
				.stroke(
					AngularGradient(
						gradient: Gradient(colors: colors),
						center: .center
					),
					style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
				)
				.rotationEffect(.degrees(-90))
		}
	}
}
