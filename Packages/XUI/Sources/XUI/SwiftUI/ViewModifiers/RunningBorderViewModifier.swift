//
//  RunningBorderViewModifier.swift
//  XUI
//
//  Created by Aung Ko Min on 4/7/25.
//

import SwiftUI

struct RunningBorderViewModifier: ViewModifier {

	let lineWidth: CGFloat
	let cornerRadius: CGFloat
	let animated: Bool

	@State private var rotation: Double = 0

	func body(content: Content) -> some View {
		content
			.overlay(
				RoundedRectangle(cornerRadius: cornerRadius)
					.strokeBorder(
						AngularGradient(
							gradient: Gradient(colors: [.indigo, .blue, .red, .orange, .indigo]),
							center: .center,
							startAngle: .degrees(rotation),
							endAngle: .degrees(rotation + 360)
						)
						.opacity(animated ? 0.6 : 0),
						lineWidth: lineWidth
					)
			)
			.onAppear {
				guard animated else { return }
				withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
					rotation = 360
				}
			}
			.onChange(of: animated) { _, newValue in
				if newValue {
					rotation = 0
					withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
						rotation = 360
					}
				} else {
					rotation = 0
				}
			}
	}
}

public extension View {
	func runningBorder(
		lineWidth: CGFloat = 1.5,
		cornerRadius: CGFloat = 12,
		animated: Bool = true
	) -> some View {
		modifier(RunningBorderViewModifier(
			lineWidth: lineWidth,
			cornerRadius: cornerRadius,
			animated: animated
		))
	}
}
