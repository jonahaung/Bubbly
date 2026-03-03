//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

actor Throttler {
    private let interval: Duration
    private var last: ContinuousClock.Instant?
    private var pendingTask: Task<Void, Never>?
    private let clock = ContinuousClock()

    init(interval: Duration) {
        self.interval = interval
    }

    func run(_ operation: @escaping @Sendable () async -> Void) {
        let now = clock.now

        if let last, now - last >= interval {
            self.last = now
            pendingTask?.cancel()
            pendingTask = nil
            Task { await operation() }
            return
        }

        pendingTask?.cancel()
        let next = (last ?? now) + interval
        pendingTask = Task {
            let delay = now.duration(to: next)
            if delay > .zero {
                try? await Task.sleep(for: delay)
            }
            guard !Task.isCancelled else { return }
            await operation()
            markRun()
        }
    }

    private func markRun() {
        last = clock.now
        pendingTask = nil
    }
}
