import SwiftUI

public extension Transaction {
	static func withAnimation(_ animation: Animation = .spring)
		-> Transaction
	{
		var transition = Transaction(animation: animation)
		transition.disablesAnimations = false
		transition.scrollPositionUpdatePreservesVelocity = true
		transition.scrollContentOffsetAdjustmentBehavior = .automatic
//		transition.isContinuous = true
		transition.tracksVelocity = true
		return transition
	}

	nonisolated(unsafe) static let withoutAnimation: Transaction = {
		var transition = Transaction(animation: nil)
		transition.disablesAnimations = true
		transition.scrollPositionUpdatePreservesVelocity = true
		transition.scrollContentOffsetAdjustmentBehavior = .automatic
//		transition.isContinuous = true
		transition.tracksVelocity = true
		return transition
	}()
}

public struct CustomLinear: CustomAnimation {
	public let duration: TimeInterval
	public func animate<V: VectorArithmetic>(value: V, time: TimeInterval,
	                                         context _: inout AnimationContext<V>) -> V?
	{
		guard time < duration else { return nil }

		return value.scaled(by: time / duration)
	}
}

public struct CustomSnapAnimation: CustomAnimation {
	public let duration: TimeInterval

	public func animate<V: VectorArithmetic>(value: V, time: TimeInterval,
	                                         context _: inout AnimationContext<V>) -> V?
	{
		guard time < duration else { return nil }

		return value.scaled(by: time / duration)
	}

	public func velocity<V: VectorArithmetic>(value: V, time _: TimeInterval,
	                                          context _: AnimationContext<V>) -> V?
	{
		value.scaled(by: -5)
	}
}

public extension Animation {
	static func customLinear(duration: TimeInterval) -> Animation {
		Animation(CustomLinear(duration: duration))
	}

	static var customLinear: Animation {
		Animation(CustomLinear(duration: 0.3))
	}

	static func customSnap(duration: TimeInterval) -> Animation {
		Animation(CustomSnapAnimation(duration: duration))
	}
}
