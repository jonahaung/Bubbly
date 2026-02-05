//
//  ThumbnailExpandedModifier.swift
//  XUI
//
//  Created by Aung Ko Min on 31/12/25.
//

import SwiftUI

public extension EnvironmentValues {
	@Entry var transitionProgress: CGFloat = 0
}
public extension AnyTransition {
	@MainActor
	static func move(
		edge: Edge,
		curve: Animation? = nil
	) -> AnyTransition {
		let base = AnyTransition.modifier(
			active: MoveModifier(edge: edge, progress: 0),
			identity: MoveModifier(edge: edge, progress: 1)
		)

		if let curve {
			return base.animation(curve)
		} else {
			return base
		}
	}
	struct MoveModifier: @MainActor AnimatableModifier {
		let edge: Edge
		var progress: CGFloat

		public var animatableData: CGFloat {
			get { progress }
			set { progress = newValue }
		}

		public func body(content: Content) -> some View {
			GeometryReader { proxy in
				content
					.transformEffect(transform(for: proxy.ignoreSafeAreaSize))
					.environment(\.transitionProgress, progress)
					.sensoryFeedback(
						.impact(weight: .medium, intensity: 0.7),
						trigger: progress == 0
					)
			}
		}
		private func transform(for size: CGSize) -> CGAffineTransform {
			let translation: CGPoint = switch edge {
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
	@MainActor
	static var invisible: AnyTransition {
		AnyTransition.modifier(
			active: InvisibleModifier(percent: 0),
			identity: InvisibleModifier(percent: 1)
		)
	}

	struct InvisibleModifier: @MainActor AnimatableModifier {
		public var percent: CGFloat
		public var animatableData: CGFloat {
			get { percent }
			set { percent = newValue }
		}

		public func body(content: Content) -> some View {
			content.opacity(percent == 1.0 ? 1 : 0)
		}
	}
}
