//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

extension Animation {
	public static func mySpring(_ duration: TimeInterval = 0.25) -> Animation {
		let mySpring = Spring(duration: duration, bounce: 0)
		let (mass, stiffness, damping) = (mySpring.mass, mySpring.stiffness, mySpring.damping)
		return .interpolatingSpring(mass: mass, stiffness: stiffness, damping: damping, initialVelocity: 1)
	}
}
extension Transaction {
	public static func withAnimation(
		_ animation: Animation = .mySpring(),
		completion: (() -> Void)? = nil
	)
	-> Transaction {
		var transaction = Transaction(animation: animation)
		transaction.disablesAnimations = false
		transaction.scrollPositionUpdatePreservesVelocity = false
		transaction.scrollContentOffsetAdjustmentBehavior = .disabled
		transaction.tracksVelocity = false
		transaction.scrollTargetAnchor = .none
		if let completion {
			transaction.addAnimationCompletion(criteria: .removed) {
				completion()
			}
		}
		return transaction
	}

	public static func withoutAnimation(completion: (() -> Void)? = nil) -> Transaction {
		var transaction = Transaction(animation: nil)
		transaction.disablesAnimations = true
		transaction.scrollPositionUpdatePreservesVelocity = false
		transaction.scrollContentOffsetAdjustmentBehavior = .disabled
		transaction.tracksVelocity = false
		transaction.scrollTargetAnchor = .none
		if let completion {
			transaction.addAnimationCompletion(criteria: .removed) {
				completion()
			}
		}
		return transaction
	}

	public static func scrollView(preservePosition: Bool, completion: (() -> Void)? = nil)
	-> Transaction {
		var transaction = Transaction()
		transaction.animation = nil
		transaction.tracksVelocity = true
		transaction.scrollPositionUpdatePreservesVelocity = preservePosition
		transaction.disablesAnimations = true
		transaction.isContinuous = true
		transaction.dismissBehavior = .destructive
		transaction.scrollContentOffsetAdjustmentBehavior = .automatic
		if let completion {
			transaction.addAnimationCompletion(criteria: .removed) {
				completion()
			}
		}
		return transaction
	}
}
