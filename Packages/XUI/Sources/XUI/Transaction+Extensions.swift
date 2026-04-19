//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI

public extension Transaction {
    static func withAnimation(
        _ animation: Animation = .timingCurve(0.0, 1.0, 0.4, 1.0, duration: 0.55),
        completion: (() -> Void)? = nil,
    )
        -> Transaction
    {
        var transaction = Transaction(animation: animation)
        transaction.disablesAnimations = false
        transaction.scrollPositionUpdatePreservesVelocity = false
        transaction.scrollContentOffsetAdjustmentBehavior = .disabled
        transaction.tracksVelocity = true
        transaction.scrollTargetAnchor = .none
        if let completion {
            transaction.addAnimationCompletion(criteria: .logicallyComplete) {
                completion()
            }
        }
        return transaction
    }

    static func withoutAnimation(completion: (() -> Void)? = nil) -> Transaction {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        transaction.scrollPositionUpdatePreservesVelocity = false
        transaction.tracksVelocity = true
        if let completion {
            transaction.addAnimationCompletion(criteria: .logicallyComplete) {
                completion()
            }
        }
        return transaction
    }

    @MainActor static func scrollPositionPreserved() -> Transaction {
        var transaction = Transaction()
        transaction.animation = nil
        transaction.tracksVelocity = true
        transaction.scrollPositionUpdatePreservesVelocity = true
        transaction.disablesAnimations = true
        transaction.isContinuous = false
        transaction.scrollContentOffsetAdjustmentBehavior = .automatic
        transaction.scrollTargetAnchor = .none
        return transaction
    }

    @MainActor static func scrollView(completion: (() -> Void)? = nil) -> Transaction {
        var transaction = Self.scrollPositionPreserved()
        if let completion {
            transaction.addAnimationCompletion(criteria: .logicallyComplete) {
                completion()
            }
        }
        return transaction
    }
}
