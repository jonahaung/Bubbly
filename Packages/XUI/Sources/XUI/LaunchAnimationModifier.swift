//
//  LaunchAnimationModifier.swift
//  XUI
//
//  Created by Aung Ko Min on 19/11/25.
//

import SwiftUI

struct LaunchAnimationModifier: ViewModifier {
	@State private var animate: Bool = false

	func body(content: Content) -> some View {
		content
			.phaseAnimator([false, true]) { view, value in
				view
					.symbolEffect(.wiggle.byLayer, value: value)
					.symbolEffect(.bounce.byLayer, value: value)
					.symbolEffect(.breathe.byLayer, value: value)
			}
			.onAppear(after: 0.5) {
				animate = true
			}
	}
}

public extension View {
	func symbolAnimation() -> some View {
		modifier(LaunchAnimationModifier())
	}
}
