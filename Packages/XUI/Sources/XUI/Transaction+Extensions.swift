//  Transaction+Extensions.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

public extension Transaction {
    static func withAnimation(
        _ animation: Animation = .timingCurve(0.0, 1.0, 0.4, 1.0, duration: 0.55),
        completion: (() -> Void)? = nil
    )
        -> Transaction
    {
        var transaction = Transaction(animation: animation)
        transaction.disablesAnimations = false
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
        transaction.scrollPositionUpdatePreservesVelocity = true
        transaction.disablesAnimations = false
        transaction.isContinuous = true
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
