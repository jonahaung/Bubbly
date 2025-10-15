//
//  RunningBorderViewModifier.swift
//  XUI
//
//  Created by Aung Ko Min on 4/7/25.
//

import SwiftUI

struct RunningBorderViewModifier: ViewModifier {
	let animated: Bool
	@State private var isAnimating = false

	func body(content: Content) -> some View {
		content
			.overlay(
				RoundedRectangle(cornerRadius: 10)
					.strokeBorder(
						AngularGradient(
							gradient: Gradient(colors: [.indigo, .blue, .red, .orange, .indigo]),
							center: .center,
							startAngle: .degrees(isAnimating ? 360 : 0),
							endAngle: .degrees(isAnimating ? 720 : 360)
						)
						.opacity(animated ? 0.5 : 0),
						lineWidth: 1.5
					)
					.animation(
						animated ? .linear(duration: 2).repeatForever(autoreverses: false) : .default,
						value: isAnimating
					)
			)
			.onAppear {
				if animated {
					isAnimating = true
				}
			}
			.onChange(of: animated) { _, newValue in
				isAnimating = newValue
			}
	}
}

public extension View {
	func runningBorder(animated: Bool) -> some View {
		modifier(RunningBorderViewModifier(animated: animated))
	}
}

#Preview {
	@Previewable @State var isAnimated = true

	VStack(spacing: 20) {
		Text("Not Animated")
			.padding()
			.runningBorder(animated: false)

		Text("Animated")
			.padding()
			.runningBorder(animated: true)

		Text("Toggle Animation")
			.padding()
			.runningBorder(animated: isAnimated)
			.onTapGesture {
				withAnimation {
					isAnimated.toggle()
				}
			}
			.overlay(
				Text(isAnimated ? "Tap to stop animation" : "Tap to start animation")
					.font(.caption)
					.foregroundColor(.secondary)
					.padding(.top, 50)
			)
	}
}
