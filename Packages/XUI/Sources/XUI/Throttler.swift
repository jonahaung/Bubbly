// © 2026 Aung Ko Min

import Foundation

public final class Throttler {
	// MARK: Lifecycle

	public init(
		delay: TimeInterval,
		option: ThrottlerOption = .trailing,
		queue: DispatchQueue = .main,
	) {
		self.delay = delay
		self.option = option
		self.queue = queue
	}

	// MARK: Public

	public enum ThrottlerOption {
		case leading
		case trailing
		case both
	}

	public func throttle(_ block: @escaping () -> Void) {
		switch option {
		case .leading:
			throttleLeading(block)
		case .trailing:
			throttleTrailing(block)
		case .both:
			throttleBoth(block)
		}
	}

	public func cancel() {
		workItem?.cancel()
		workItem = nil
		pendingExecution = false
	}

	// MARK: Private

	private let queue: DispatchQueue
	private let delay: TimeInterval
	private let option: ThrottlerOption
	private var workItem: DispatchWorkItem? = nil
	private var lastExecutionTime: Date? = nil
	private var pendingExecution: Bool = false

	private func throttleLeading(_ block: @escaping () -> Void) {
		let now = Date()

		if lastExecutionTime == nil || now.timeIntervalSince(lastExecutionTime!) >= delay {
			execute(block)
		}
	}

	private func throttleTrailing(_ block: @escaping () -> Void) {
		workItem?.cancel()
		let newWorkItem = DispatchWorkItem { [weak self] in
			self?.execute(block)
		}

		workItem = newWorkItem
		queue.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
	}

	private func throttleBoth(_ block: @escaping () -> Void) {
		let now = Date()
		if lastExecutionTime == nil || now.timeIntervalSince(lastExecutionTime!) >= delay {
			execute(block)
			return
		}
		if pendingExecution {
			return
		}

		pendingExecution = true

		let remainingDelay = delay - now.timeIntervalSince(lastExecutionTime!)
		let newWorkItem = DispatchWorkItem { [weak self] in
			self?.pendingExecution = false
			self?.execute(block)
		}

		workItem = newWorkItem
		queue.asyncAfter(deadline: .now() + remainingDelay, execute: newWorkItem)
	}

	private func execute(_ block: () -> Void) {
		lastExecutionTime = Date()
		block()
	}
}
