//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

extension Transaction {
	public static func withAnimation(
		_ animation: Animation = .anticipateOvershoot(duration: 0.35),
		completion: (@MainActor () -> Void)? = nil
	)
	-> Transaction {
		var transaction = Transaction(animation: animation)
		transaction.disablesAnimations = false
		transaction.scrollPositionUpdatePreservesVelocity = false
		transaction.scrollContentOffsetAdjustmentBehavior = .disabled
		transaction.tracksVelocity = true
		transaction.scrollTargetAnchor = .none
		if let completion {
			transaction.addAnimationCompletion(criteria: .removed) {
				Task { @MainActor in
					completion()
				}
			}
		}
		return transaction
	}


	public static func withoutAnimation(completion: (@MainActor () -> Void)? = nil) -> Transaction {
		var transaction = Transaction(animation: nil)
		transaction.disablesAnimations = true
		transaction.scrollPositionUpdatePreservesVelocity = false
		transaction.scrollContentOffsetAdjustmentBehavior = .disabled
		transaction.tracksVelocity = false
		transaction.scrollTargetAnchor = .none
		if let completion {
			transaction.addAnimationCompletion(criteria: .removed) {
				Task { @MainActor in
					completion()
				}
			}
		}
		return transaction
	}

	@MainActor public static let scrollPositionPreserved: Transaction = {
		var transaction = Transaction()
		transaction.animation = nil
		transaction.tracksVelocity = true
		transaction.scrollPositionUpdatePreservesVelocity = true
		transaction.disablesAnimations = true
		transaction.isContinuous = false
		transaction.dismissBehavior = .destructive
		transaction.scrollContentOffsetAdjustmentBehavior = .disabled
		transaction.scrollTargetAnchor = .bottom
		return transaction
	}()

	@MainActor public static func scrollView(completion: (@MainActor () -> Void)? = nil) -> Transaction {
		var transaction = Self.scrollPositionPreserved
		if let completion {
			transaction.addAnimationCompletion(criteria: .removed) {
				Task { @MainActor in
					completion()
				}
			}
		}
		return transaction
	}
}
