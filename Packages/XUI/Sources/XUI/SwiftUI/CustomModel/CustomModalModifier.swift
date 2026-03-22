//
//  MoveModifier.swift
//  XUI
//
//  Created by Aung Ko Min on 8/3/26.
//

import SwiftUI

public extension EnvironmentValues {
	@Entry var transitionProgress: CGFloat = 0
}

extension AnyTransition {
	struct CustomModalModifier: @preconcurrency AnimatableModifier {
		let edge: Edge
		var progress: CGFloat

		public var animatableData: CGFloat {
			get { progress }
			set { progress = newValue }
		}

		public func body(content: Content) -> some View {
			GeometryReader { proxy in
				content
					.transformEffect(transform(for: proxy.size))
					.environment(\.transitionProgress, progress)
					.sensoryFeedback(
						.impact(weight: .medium, intensity: 0.7),
						trigger: progress == 0
					)
			}
		}

		private func transform(for size: CGSize) -> CGAffineTransform {
			let translation =
			switch edge {
			case .bottom:
				CGPoint(x: 0, y: size.height * (1 - progress))
			case .top:
				CGPoint(x: 0, y: -size.height * (1 - progress))
			case .leading:
				CGPoint(x: -size.width * (1 - progress), y: 0)
			case .trailing:
				CGPoint(x: size.width * (1 - progress), y: 0)
			}
			return CGAffineTransform(
				translationX: translation.x,
				y: translation.y
			)
		}
	}
}
public extension AnyTransition {
	static func modal(
		edge: Edge,
		curve: Animation? = nil
	) -> AnyTransition {
		let base = AnyTransition.modifier(
			active: CustomModalModifier(edge: edge, progress: 0),
			identity: CustomModalModifier(edge: edge, progress: 1)
		)
		if let curve {
			return base.animation(curve)
		} else {
			return base
		}
	}
}
