//
//  PhaseAnimation.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 13/5/24.
//

import SwiftUI

private struct PhaseAnimationModifier: ViewModifier {
	let phases: [PhaseAnimationType]
	let trigger: String?
	func body(content: Content) -> some View {
		if phases.isEmpty {
			content
		} else {
			if let trigger {
				content
					.phaseAnimator(phases, trigger: trigger, content: { view, phase in
						view
							.scaleEffect(phase.scale)
							.rotationEffect(phase.angle)
							.offset(x: phase.size.x, y: phase.size.y)
					}, animation: { phase in
						switch phase {
						case .rotate:
							.easeInOut(duration: 0.8)
						case let .scale(scale):
							.easeInOut(duration: 1 / scale)
						}
					})
			} else {
				content
					.phaseAnimator(phases, content: { view, phase in
						view
							.scaleEffect(phase.scale)
							.rotationEffect(phase.angle)
							.offset(x: phase.size.x, y: phase.size.y)
					}, animation: { phase in
						switch phase {
						case .rotate:
							.linear(duration: 0.8)
						case let .scale(scale):
							.linear(duration: 0.5 / scale)
						}
					})
			}
		}
	}
}

public enum CardinalPoint: Double, CaseIterable {
	case north = 0
	case east = 90
	case south = 180
	case west = 270
	case northFullCircle = 360

	/// SF Symbol (↗) is 45 degrees rotated, so we substract it to compensate
	public var angle: Angle {
		.degrees(rawValue)
	}
}

public enum PhaseAnimationType: Hashable {
	case scale(CGFloat)
	case rotate(CardinalPoint)

	var scale: CGFloat {
		switch self {
		case let .scale(value):
			value
		default:
			1
		}
	}

	var angle: Angle {
		switch self {
		case let .rotate(value):
			value.angle
		default:
			.zero
		}
	}

	var size: (x: Double, y: Double) {
		switch self {
		default:
			(0, 0)
		}
	}
}

public extension View {
	func phaseAnimation(_ phases: [PhaseAnimationType], _ trigger: String? = nil) -> some View {
		ModifiedContent(
			content: self,
			modifier: PhaseAnimationModifier(phases: phases, trigger: trigger)
		)
	}
}
