//  DisplayLink.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import UIKit

public final class DisplayLink {
    public enum State {
        case inactive
        case running
    }

    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    public private(set) var state: State = .inactive
    private let fixedInterval: CFTimeInterval
    private var targetInterval: CFTimeInterval

    public init(_ interval: CFTimeInterval = 1) {
        fixedInterval = interval
        targetInterval = interval
    }

//    public var onUpdate: ((Double) -> Void)?

    public var onTargetReached: ((Double) -> Void)?

    public func start(_ interval: CFTimeInterval? = nil) {
        targetInterval = if let interval {
            interval
        } else {
            fixedInterval
        }
        if state == .running {
            stop()
        }

        state = .running
        startTime = CACurrentMediaTime()

        let link = CADisplayLink(target: self, selector: #selector(handleFrame))
        link.preferredFrameRateRange = .init(minimum: 60, maximum: 60)
        link.add(to: .current, forMode: .common)
        displayLink = link
    }

    public func stop() {
        guard state == .running else { return }
        displayLink?.invalidate()
        displayLink = nil
        state = .inactive
        startTime = 0
    }

    @objc private func handleFrame() {
        guard state == .running else { return }

        let elapsed = CACurrentMediaTime() - startTime
//        if let onUpdate {
//            onUpdate(elapsed)
//        }
        if elapsed >= targetInterval {
            stop()
            onTargetReached?(elapsed)
        }
    }
}
