//
//  SmoothPhysicsScrollTargetBehavior.swift
//  Conversation
//
//  Created by Aung Ko Min on 11/3/26.
//

//
//  SmoothPhysicsScrollTargetBehavior.swift
//

import SwiftUI
import UIKit

/// A lightweight scroll physics behavior designed to feel smoother than UIKit deceleration.
/// Optimized for feeds, chats, and timelines.
public struct SmoothPhysicsScrollTargetBehavior: ScrollTargetBehavior {

	// MARK: - Configuration

	/// base friction applied to velocity
	public var friction: CGFloat

	/// velocity where fast deceleration begins
	public var fastThreshold: CGFloat

	/// max velocity allowed
	public var maxVelocity: CGFloat

	/// distance where boundary resistance starts
	public var boundaryDistance: CGFloat

	/// velocity response curve
	public var curve: ResponseCurve

	// MARK: - Response Curve

	public enum ResponseCurve {
		case linear
		case easeOut
		case cubic

		func map(_ t: CGFloat) -> CGFloat {
			switch self {

			case .linear:
				return t

			case .easeOut:
				return 1 - pow(1 - t, 2)

			case .cubic:
				return t * t * t
			}
		}
	}

	// MARK: - Init

	public init(
		friction: CGFloat = 0.82,
		fastThreshold: CGFloat = 1800,
		maxVelocity: CGFloat = 8000,
		boundaryDistance: CGFloat = 180,
		curve: ResponseCurve = .easeOut
	) {
		self.friction = friction
		self.fastThreshold = fastThreshold
		self.maxVelocity = maxVelocity
		self.boundaryDistance = boundaryDistance
		self.curve = curve
	}

	// MARK: - ScrollTargetBehavior

	public func updateTarget(
		_ target: inout ScrollTarget,
		context: TargetContext
	) {

		guard context.contentSize.height > context.containerSize.height else {
			target.rect.origin.y = 0
			return
		}

		let velocity = clampVelocity(context.velocity.dy)

		let minY: CGFloat = 0
		let maxY = context.contentSize.height - context.containerSize.height

		let displacement = computeDisplacement(velocity)

		var newY = target.rect.origin.y + displacement

		newY = applyBoundaryResistance(
			position: newY,
			minY: minY,
			maxY: maxY,
			velocity: velocity
		)

		target.rect.origin.y = clamp(newY, minY, maxY)
	}

	// MARK: - Physics

	private func computeDisplacement(_ velocity: CGFloat) -> CGFloat {

		let direction: CGFloat = velocity > 0 ? 1 : -1
		let v = abs(velocity)

		let normalized = min(v / maxVelocity, 1)

		let curved = curve.map(normalized)

		let adaptiveFriction: CGFloat

		if v > fastThreshold {
			adaptiveFriction = friction * 0.75
		} else {
			adaptiveFriction = friction
		}

		let travel = curved * 900 * adaptiveFriction

		return direction * travel
	}

	// MARK: - Boundary Resistance

	private func applyBoundaryResistance(
		position: CGFloat,
		minY: CGFloat,
		maxY: CGFloat,
		velocity: CGFloat
	) -> CGFloat {

		if position < minY {

			let distance = minY - position

			let resistance = resistanceCurve(distance)

			return minY - distance * resistance
		}

		if position > maxY {

			let distance = position - maxY

			let resistance = resistanceCurve(distance)

			return maxY + distance * resistance
		}

		return position
	}

	private func resistanceCurve(_ distance: CGFloat) -> CGFloat {

		let normalized = min(distance / boundaryDistance, 1)

		let resistance = pow(1 - normalized, 2)

		return max(resistance, 0.15)
	}

	// MARK: - Helpers

	private func clampVelocity(_ v: CGFloat) -> CGFloat {
		max(-maxVelocity, min(v, maxVelocity))
	}

	private func clamp(_ v: CGFloat, _ minV: CGFloat, _ maxV: CGFloat) -> CGFloat {
		max(minV, min(v, maxV))
	}
}

extension ScrollTargetBehavior where Self == SmoothPhysicsScrollTargetBehavior {

	public static var smoothFeed: SmoothPhysicsScrollTargetBehavior {
		.init(
			friction: 0.82,
			fastThreshold: 1700,
			curve: .easeOut
		)
	}

	public static var fastFeed: SmoothPhysicsScrollTargetBehavior {
		.init(
			friction: 0.72,
			fastThreshold: 1400,
			curve: .cubic
		)
	}

	public static var precise: SmoothPhysicsScrollTargetBehavior {
		.init(
			friction: 0.9,
			fastThreshold: 2200,
			curve: .linear
		)
	}
}
