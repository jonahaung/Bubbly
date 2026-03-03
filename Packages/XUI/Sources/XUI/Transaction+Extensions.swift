//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public extension Transaction {
    static func withAnimation(_ animation: Animation = .easeInOut, completion: (() -> Void)? = nil)
        -> Transaction {
        var transaction = Transaction(animation: animation)
        transaction.disablesAnimations = false
        transaction.scrollPositionUpdatePreservesVelocity = true
        transaction.scrollContentOffsetAdjustmentBehavior = .automatic
        transaction.tracksVelocity = true
        transaction.scrollTargetAnchor = .center
        transaction.addAnimationCompletion(criteria: .removed) {
            completion?()
        }
        return transaction
    }

    @MainActor static let withoutAnimation: Transaction = {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        transaction.scrollPositionUpdatePreservesVelocity = false
        transaction.scrollContentOffsetAdjustmentBehavior = .disabled
        transaction.tracksVelocity = false
        transaction.scrollTargetAnchor = .none
        return transaction
    }()

    static func scrollView(preservePosition: Bool, completion: (() -> Void)? = nil) -> Transaction {
        var transaction = Transaction()
        transaction.animation = nil
        transaction.tracksVelocity = true
        transaction.scrollPositionUpdatePreservesVelocity = preservePosition
        transaction.disablesAnimations = true
        transaction.isContinuous = true
        transaction.dismissBehavior = .destructive
        transaction.scrollContentOffsetAdjustmentBehavior = .automatic
        transaction.addAnimationCompletion(criteria: .removed) {
            completion?()
        }
        return transaction
    }
}
