//
//  ToastPresenter.swift
//  XUI
//
//  Created by Aung Ko Min on 18/10/25.
//

import SwiftUI
import QuartzCore

import SwiftUI
import QuartzCore

@MainActor
@Observable
public final class ToastPresenter {
	public private(set) var toast: Toast?
	private var queue: [Toast] = []

	@ObservationIgnored
	private var displayLink: CADisplayLink?
	@ObservationIgnored
	private var startTime: CFTimeInterval?
	@ObservationIgnored
	private var elapsedTime: TimeInterval = 0.0

	// MARK: - Public API

	public func show(_ value: Toast?) {
		guard let value else { return }
		queue.append(value)
		processQueue()
	}

	public static func show(_ value: Toast?) {
		shared.show(value)
	}

	public static func show(_ text: String, action: (@MainActor @Sendable () -> Void)? = nil) {
		shared.show(.init(message: text, action: action))
	}

	public func dismiss() {
		stopTracking()
		toast = nil
		processQueue()
	}

	// MARK: - Shared Singleton
	public static var shared: ToastPresenter {
		get { _shared.wrappedValue }
		set { _shared.wrappedValue = newValue }
	}
	private static var _shared = Atomic(wrappedValue: ToastPresenter())
}

// MARK: - Queue Processing
private extension ToastPresenter {
	func processQueue() {
		// If no current toast and queue has items
		guard toast == nil, !queue.isEmpty else { return }
		let next = queue.removeFirst()
		toast = next
		startTracking()
	}
}

// MARK: - Timer Handling
private extension ToastPresenter {
	func startTracking() {
		stopTracking() // Ensure previous one is invalidated

		guard toast != nil else { return }

		startTime = CACurrentMediaTime()
		elapsedTime = 0

		let link = CADisplayLink(target: self, selector: #selector(update))
		// You only need to check ~1 per 60th of a second at most; higher accuracy is overkill for toast durations.
		link.preferredFrameRateRange = CAFrameRateRange(minimum: 1, maximum: 30, preferred: 10)
		link.add(to: .main, forMode: .common)
		displayLink = link
	}

	func stopTracking() {
		displayLink?.invalidate()
		displayLink = nil
		startTime = nil
	}

	@objc private func update(displayLink: CADisplayLink) {
		guard let startTime = startTime, let toast else { return }
		elapsedTime = CACurrentMediaTime() - startTime
		if elapsedTime > toast.duration {
			dismiss()
		}
	}
}
