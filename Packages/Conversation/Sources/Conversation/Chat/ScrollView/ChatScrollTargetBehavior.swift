//
//  ChatScrollTargetBehavior.swift
//  Conversation
//
//  Created by Aung Ko Min on 10/3/26.
//

import SwiftUI
import Core

//public struct ChatScrollTargetBehavior: ScrollTargetBehavior {
//
//	private let isEnabled: Bool
//	private let topMargin: CGFloat
//	private let slowdownFactor: CGFloat
//	private let momentumFactor: CGFloat
//	private let dampingRatio: CGFloat
//	private let onTargetChanged: @Sendable (CGFloat) -> Void
//
//	public init(
//		isEnabled: Bool,
//		topMargin: CGFloat = ChatLayoutConstants.bottomBarHeight,
//		slowdownFactor: CGFloat = 3,
//		momentumFactor: CGFloat = 0.7,
//		dampingRatio: CGFloat = 0.8,
//		onTargetChanged: @Sendable @escaping (CGFloat) -> Void
//	) {
//		self.isEnabled = isEnabled
//		self.topMargin = topMargin
//		self.slowdownFactor = slowdownFactor
//		self.momentumFactor = momentumFactor
//		self.dampingRatio = dampingRatio
//		self.onTargetChanged = onTargetChanged
//	}
//
//	public func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
//		let originalTarget = context.originalTarget.rect.minY
//		let contentHeight = context.contentSize.height
//		let containerHeight = context.containerSize.height
//
//		let minOffset: CGFloat = 0
//		let maxOffset = max(0, contentHeight - containerHeight)
//
//		guard maxOffset > 0 else {
//			target.rect.origin.y = 0
//			onTargetChanged(target.rect.origin.y)
//			return
//		}
//
//		let proposedY = target.rect.origin.y
//		let velocity = context.velocity.dy
////
//		let topBoundary = minOffset + topMargin
////
//		// momentum
//		let momentumOffset = velocity * momentumFactor * dampingRatio
//		var adjustedY = proposedY + momentumOffset
////
////		// top protection
//		if adjustedY < topBoundary && proposedY < originalTarget {
//
//			let overshoot = topBoundary - adjustedY
//			let normalized = min(1, overshoot / topMargin)
//
//			let slowdown = 1 + (slowdownFactor - 1) * normalized
//
//			adjustedY = topBoundary - overshoot / slowdown
//			adjustedY = max(minOffset, min(adjustedY, maxOffset))
//			if isEnabled {
//				target.rect.origin.y = adjustedY
//			}
//		}
//		if adjustedY > maxOffset && proposedY > originalTarget {
//			adjustedY = max(minOffset, min(adjustedY, maxOffset))
//			if isEnabled {
//				target.rect.origin.y = adjustedY
//			}
//		}
//		onTargetChanged(adjustedY)
////
//	}
//}

import SwiftUI
import UIKit

/// A scroll target behavior that slows down and never crosses top and bottom margins
public struct BoundedScrollTargetBehavior: ScrollTargetBehavior {
	public let topMargin: CGFloat
	public let bottomMargin: CGFloat
	public let slowdownFactor: CGFloat
	public let elasticity: CGFloat

	/// Creates a bounded scroll target behavior
	/// - Parameters:
	///   - topMargin: The margin from the top where slowdown begins (default: 50)
	///   - bottomMargin: The margin from the bottom where slowdown begins (default: 50)
	///   - slowdownFactor: How much to slow down at boundaries (higher = more slowdown, default: 3.0)
	///   - elasticity: How much elastic stretch at boundaries (0 = no stretch, 1 = full stretch, default: 0.2)
	public init(
		topMargin: CGFloat = 50,
		bottomMargin: CGFloat = 50,
		slowdownFactor: CGFloat = 3.0,
		elasticity: CGFloat = 0.2
	) {
		self.topMargin = topMargin
		self.bottomMargin = bottomMargin
		self.slowdownFactor = slowdownFactor
		self.elasticity = elasticity
	}

	public func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
		// Get the content size and container size
		let contentSize = context.contentSize
		let containerSize = context.containerSize

		// Calculate the valid scrollable range
		let minOffset: CGFloat = 0 // Top boundary
		let maxOffset: CGFloat = max(0, contentSize.height - containerSize.height) // Bottom boundary

		// If content is smaller than container, no scrolling needed
		guard maxOffset > 0 else {
			target.rect.origin.y = 0
			return
		}

		// Get the proposed offset
		let proposedY = target.rect.origin.y

		// Calculate the effective boundaries with margins
		let topBoundary = minOffset + topMargin
		let bottomBoundary = maxOffset - bottomMargin

		// Ensure bottom boundary is valid
		let effectiveBottomBoundary = max(topBoundary, bottomBoundary)

		var adjustedY = proposedY

		// Apply elastic slowdown when approaching or crossing boundaries
		if proposedY < topBoundary {
			// Above top margin - elastic slowdown
			let overshoot = topBoundary - proposedY
			let elasticOvershoot = overshoot * elasticity
			let slowdown = 1.0 + (slowdownFactor - 1.0) * min(1.0, overshoot / 100)
			adjustedY = topBoundary - (elasticOvershoot / slowdown)
		} else if proposedY > effectiveBottomBoundary {
			// Below bottom margin - elastic slowdown
			let overshoot = proposedY - effectiveBottomBoundary
			let elasticOvershoot = overshoot * elasticity
			let slowdown = 1.0 + (slowdownFactor - 1.0) * min(1.0, overshoot / 100)
			adjustedY = effectiveBottomBoundary + (elasticOvershoot / slowdown)
		}

		// Final clamping to ensure we never cross the absolute boundaries
		adjustedY = max(minOffset, min(adjustedY, maxOffset))

		target.rect.origin.y = adjustedY
	}
}

/// A scroll target behavior with velocity-based momentum and boundary protection
public struct MomentumBoundedScrollTargetBehavior: ScrollTargetBehavior {
	public let topMargin: CGFloat
	public let bottomMargin: CGFloat
	public let slowdownFactor: CGFloat
	public let momentumFactor: CGFloat
	public let dampingRatio: CGFloat

	/// Creates a momentum-based bounded scroll target behavior
	/// - Parameters:
	///   - topMargin: The margin from the top where slowdown begins (default: 50)
	///   - bottomMargin: The margin from the bottom where slowdown begins (default: 50)
	///   - slowdownFactor: How much to slow down at boundaries (higher = more slowdown, default: 3.0)
	///   - momentumFactor: How much momentum to preserve (0-1, default: 0.7)
	///   - dampingRatio: How quickly momentum fades (0-1, default: 0.8)
	public init(
		topMargin: CGFloat = 50,
		bottomMargin: CGFloat = 50,
		slowdownFactor: CGFloat = 3.0,
		momentumFactor: CGFloat = 0.7,
		dampingRatio: CGFloat = 0.2
	) {
		self.topMargin = topMargin
		self.bottomMargin = bottomMargin
		self.slowdownFactor = slowdownFactor
		self.momentumFactor = momentumFactor
		self.dampingRatio = dampingRatio
	}

	public func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
		let contentSize = context.contentSize
		let containerSize = context.containerSize

		// Calculate boundaries
		let minOffset: CGFloat = 0
		let maxOffset: CGFloat = max(0, contentSize.height - containerSize.height)

		// If content is smaller than container, no scrolling needed
		guard maxOffset > 0 else {
			target.rect.origin.y = 0
			return
		}

		let topBoundary = minOffset + topMargin
		let bottomBoundary = maxOffset - bottomMargin
		let effectiveBottomBoundary = max(topBoundary, bottomBoundary)

		// Get proposed position and velocity
		let proposedY = target.rect.origin.y
		let velocity = context.velocity.dy

		// Calculate momentum with damping
		let momentumOffset = velocity * momentumFactor * dampingRatio * 0.1

		var adjustedY = proposedY + momentumOffset

		// Apply progressive slowdown based on distance from boundaries
		if adjustedY < topBoundary {
			let distanceFromBoundary = topBoundary - adjustedY
			let slowdown = 1.0 + (slowdownFactor - 1.0) * min(1.0, distanceFromBoundary / 100)
			adjustedY = topBoundary - (distanceFromBoundary / slowdown)
		} else if adjustedY > effectiveBottomBoundary {
			let distanceFromBoundary = adjustedY - effectiveBottomBoundary
			let slowdown = 1.0 + (slowdownFactor - 1.0) * min(1.0, distanceFromBoundary / 100)
			adjustedY = effectiveBottomBoundary + (distanceFromBoundary / slowdown)
		}

		// Ensure we never cross absolute boundaries
		adjustedY = max(minOffset, min(adjustedY, maxOffset))

		target.rect.origin.y = adjustedY
	}
}
