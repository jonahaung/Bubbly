//
//  Debouncer.swift
//  Conversation
//
//  Created by Aung Ko Min on 25/2/26.
//

import Foundation

actor Debouncer {

	private let interval: Duration
	private let clock = ContinuousClock()

	private var pendingTask: Task<Void, Never>?
	private var lastFire: ContinuousClock.Instant?

	private let leading: Bool

	init(
		interval: Duration,
		leading: Bool = false
	) {
		self.interval = interval
		self.leading = leading
	}

	func run(
		_ operation: @escaping @Sendable () async -> Void
	) {
		pendingTask?.cancel()

		let now = clock.now

		if leading, lastFire == nil {
			lastFire = now
			Task { await operation() }
			return
		}

		pendingTask = Task { [interval, clock] in
			try? await Task.sleep(for: interval)

			guard !Task.isCancelled else { return }

			await operation()
			await markFired()
		}
	}

	func cancel() {
		pendingTask?.cancel()
		pendingTask = nil
	}

	private func markFired() async {
		await Task.yield()
		lastFire = clock.now
		pendingTask = nil
	}
}

