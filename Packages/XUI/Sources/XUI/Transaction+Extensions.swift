//
//  Transaction+Extensions.swift
//  XUI
//
//  Created by Aung Ko Min on 20/10/25.
//

import SwiftUI

public extension Transaction {
	static func withAnimation(_ animation: Animation = .interpolatingSpring) -> Transaction {
		var transition = Transaction(animation: animation)
		transition.disablesAnimations = false
		transition.scrollPositionUpdatePreservesVelocity = true
		transition.scrollContentOffsetAdjustmentBehavior = .disabled
		transition.isContinuous = false
		return transition
	}

	nonisolated(unsafe) static let withoutAnimation: Transaction = {
		var transition = Transaction(animation: nil)
		transition.disablesAnimations = true
		transition.scrollPositionUpdatePreservesVelocity = true
		transition.scrollContentOffsetAdjustmentBehavior = .disabled
		transition.tracksVelocity = true
		return transition
	}()
}
