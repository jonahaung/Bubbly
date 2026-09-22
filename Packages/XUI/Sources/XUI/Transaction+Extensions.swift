//  Transaction+Extensions.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

public extension Transaction {
    static func withAnimation(
        _ animation: Animation = .linear(duration: 0.25),
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
        transaction.tracksVelocity = false
        transaction.isContinuous = true
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
        transaction.scrollTargetAnchor = .none
        transaction.isContinuous = true
        transaction.tracksVelocity = false
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
