//
//  Transaction++.swift
//  XUI
//
//  Created by Aung Ko Min on 20/10/25.
//

import SwiftUI

public extension Transaction {
    @MainActor
    static let withAnimation: Transaction = {
		var transition = Transaction(animation: .interpolatingSpring)
        transition.disablesAnimations = false
        transition.scrollPositionUpdatePreservesVelocity = false
		transition.scrollContentOffsetAdjustmentBehavior = .automatic
		transition.tracksVelocity = false
        return transition
    }()

    @MainActor
    static let withoutAnimation: Transaction = {
        var transition = Transaction(animation: nil)
        transition.disablesAnimations = true
        transition.scrollPositionUpdatePreservesVelocity = false
        transition.scrollContentOffsetAdjustmentBehavior = .disabled
        transition.tracksVelocity = false
        return transition
    }()
}
