//
//  Throttler.swift
//  Conversation
//
//  Created by Aung Ko Min on 26/9/26.
//

import Foundation

final class Throttler {
    enum Edge {
        case leading
        case trailing
        case both
    }

    private let queue: DispatchQueue
    private var lastExecution: Date = .distantPast
    private var pendingWorkItem: DispatchWorkItem?
    private var pendingAction: (() -> Void)?
    private let lock = NSLock()

    let interval: TimeInterval
    let edge: Edge

    init(
        interval: TimeInterval,
        edge: Edge = .leading,
        queue: DispatchQueue = .main
    ) {
        self.interval = interval
        self.edge = edge
        self.queue = queue
    }

    deinit { cancel() }

    func throttle(action: @Sendable @escaping () -> Void) {
        let now = Date()
        var executeNow = false
        var scheduleTrailing = false
        var delay: TimeInterval = 0

        lock.lock()
        let elapsed = now.timeIntervalSince(lastExecution)
        let canExecute = elapsed >= interval

        switch edge {
        case .leading:
            if canExecute {
                lastExecution = now
                executeNow = true
            }
        case .trailing:
            pendingAction = action
            pendingWorkItem?.cancel()
            delay = max(0, interval - elapsed)
            scheduleTrailing = true
        case .both:
            if canExecute {
                lastExecution = now
                pendingAction = nil
                pendingWorkItem?.cancel()
                pendingWorkItem = nil
                executeNow = true
            } else {
                pendingAction = action
                pendingWorkItem?.cancel()
                delay = interval - elapsed
                scheduleTrailing = true
            }
        }
        lock.unlock()

        if executeNow {
            queue.async(execute: action)
        }

        if scheduleTrailing {
            let workItem = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.lock.lock()
                let action = self.pendingAction
                self.pendingAction = nil
                self.pendingWorkItem = nil
                self.lastExecution = Date()
                self.lock.unlock()
                action?()
            }

            lock.lock()
            pendingWorkItem = workItem
            lock.unlock()

            queue.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }

    func cancel() {
        lock.lock()
        defer { lock.unlock() }
        pendingWorkItem?.cancel()
        pendingWorkItem = nil
        pendingAction = nil
    }
}
