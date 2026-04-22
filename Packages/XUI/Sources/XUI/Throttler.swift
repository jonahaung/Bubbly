//  Throttler.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Foundation

public final class Throttler {

    public enum Option {
        case leading
        case trailing
        case both
    }

    public init(
        delay: TimeInterval,
        option: Option = .trailing,
        queue: DispatchQueue = .main
    ) {
        self.delay = delay
        self.option = option
        self.queue = queue
    }

    // MARK: Public

    public func throttle(_ block: @escaping () -> Void) {
        lock.lock()
        defer { lock.unlock() }

        let now = DispatchTime.now().uptimeNanoseconds
        let delayNs = UInt64(delay * 1_000_000_000)

        switch option {

        case .leading:
            if now - lastExecution >= delayNs {
                execute(now, block)
            }

        case .trailing:
            schedule(after: delayNs, block)

        case .both:
            if now - lastExecution >= delayNs {
                execute(now, block)
                return
            }

            guard !pending else { return }
            pending = true

            let remaining = delayNs - (now - lastExecution)
            schedule(after: remaining) { [weak self] in
                guard let self else { return }
                pending = false
                block()
            }
        }
    }

    public func cancel() {
        lock.lock()
        defer { lock.unlock() }
        workItem?.cancel()
        workItem = nil
        pending = false
    }

    // MARK: Private

    private let queue: DispatchQueue
    private let delay: TimeInterval
    private let option: Option

    private let lock: NSLock = .init()

    private var workItem: DispatchWorkItem?
    private var lastExecution: UInt64 = 0
    private var pending = false

    private func schedule(after ns: UInt64, _ block: @escaping () -> Void) {
        workItem?.cancel()

        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }

            lock.lock()
            let now = DispatchTime.now().uptimeNanoseconds
            lastExecution = now
            lock.unlock()

            block()
        }

        workItem = item
        queue.asyncAfter(deadline: .now() + .nanoseconds(Int(ns)), execute: item)
    }

    private func execute(_ now: UInt64, _ block: () -> Void) {
        lastExecution = now
        block()
    }
}
