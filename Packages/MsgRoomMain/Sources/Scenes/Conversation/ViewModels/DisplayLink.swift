//
//  DisplayLink.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 19/10/25.
//


import UIKit

public final class DisplayLink {

	public enum State {
		case inactive
		case running
	}

	private var displayLink: CADisplayLink?
	private var startTime: CFTimeInterval = 0
	private(set) public var state: State = .inactive

	private var targetInterval: CFTimeInterval

	public init(interval: CFTimeInterval = 2) {
		self.targetInterval = interval
	}

	/// Called every frame with elapsed time in seconds.
	public var onUpdate: ((Double) -> Void)?

	/// Called once when the target interval is exceeded.
	public var onTargetReached: ((Double) -> Void)?

	/// Starts the display link with a new interval.
	public func start(interval: CFTimeInterval? = nil) {
		if let interval = interval {
			self.targetInterval = interval
		}

		// If already running, restart
		if state == .running {
			stop()
		}

		state = .running
		startTime = CACurrentMediaTime()

		let link = CADisplayLink(target: self, selector: #selector(handleFrame))
		link.preferredFrameRateRange = .init(minimum: 60, maximum: 60)
		link.add(to: .main, forMode: .common)
		displayLink = link
	}

	/// Stops and resets the timer.
	public func stop() {
		guard state == .running else { return }
		displayLink?.invalidate()
		displayLink = nil
		state = .inactive
		startTime = 0

		// Notify update closure with reset value
		onUpdate?(0)
	}

	@objc private func handleFrame() {
		guard state == .running else { return }

		let elapsed = CACurrentMediaTime() - startTime
		onUpdate?(elapsed)

		if elapsed >= targetInterval {
			stop()
			onTargetReached?(elapsed)
		}
	}
}
