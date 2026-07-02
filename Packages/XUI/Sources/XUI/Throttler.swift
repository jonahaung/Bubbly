//
//  Throttler.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Foundation

public final class Throttler: @unchecked Sendable {

    public enum Option: Sendable {
        case leading
        case trailing
        case both
    }

    private let delay: TimeInterval
    private let option: Option
    private let queue: DispatchQueue
    private let lock = NSLock()

    private var lastExecution: DispatchTime?
    private var workItem: DispatchWorkItem?
    private var latestBlock: (() -> Void)?

    public init(
        delay: TimeInterval,
        option: Option = .leading,
        queue: DispatchQueue = .main
    ) {
        self.delay = max(0, delay)
        self.option = option
        self.queue = queue
    }

    public func throttle(_ block: @escaping () -> Void) {
        let action: (() -> Void)?

        lock.lock()

        let now = DispatchTime.now()
        let delayNs = UInt64(delay * 1_000_000_000)
        let elapsed = lastExecution.map { now.uptimeNanoseconds - $0.uptimeNanoseconds } ?? .max
        let canExecute = elapsed >= delayNs

        switch option {
        case .leading:
            if canExecute {
                lastExecution = now
                action = block
            } else {
                action = nil
            }

        case .trailing:
            latestBlock = block
            action = nil
            scheduleLocked(after: canExecute ? 0 : delayNs - elapsed)

        case .both:
            if canExecute {
                lastExecution = now
                action = block
            } else {
                latestBlock = block
                action = nil
                scheduleLocked(after: delayNs - elapsed)
            }
        }

        lock.unlock()

        action?()
    }

    public func cancel() {
        lock.lock()
        workItem?.cancel()
        workItem = nil
        latestBlock = nil
        lock.unlock()
    }

    private func scheduleLocked(after ns: UInt64) {
        guard workItem == nil else { return }

        let item = DispatchWorkItem { [weak self] in
            self?.executeTrailing()
        }

        workItem = item
        queue.asyncAfter(
            deadline: .now() + .nanoseconds(Int(ns)),
            execute: item
        )
    }

    private func executeTrailing() {
        let block: (() -> Void)?

        lock.lock()
        block = latestBlock
        latestBlock = nil
        workItem = nil
        lastExecution = .now()
        lock.unlock()

        block?()
    }
}
