//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@MainActor
@Observable
public final class ToastPresenter {
    public var toast: Toast?
	private var queue = Deque<Toast>()

    @ObservationIgnored
    private var displayLink: CADisplayLink?
    @ObservationIgnored
    private var startTime: CFTimeInterval?
    @ObservationIgnored
    private var elapsedTime: TimeInterval = 0.0

    public func show(_ value: Toast?) {
        guard let value else { return }
		queue.enqueue(value)
        processQueue()
    }

    public static func show(_ value: Toast?) {
        shared.show(value)
    }

    @MainActor
    public static func show(_ text: String, allowsBackgroundTap: Bool) {
        shared.show(.init(message: text, allowsBackgroundTap: allowsBackgroundTap))
    }

    @MainActor
    public static func show(
        allowsBackgroundTap: Bool,
        @ViewBuilder content: () -> some View,
        action: @MainActor @escaping () -> Void
    ) {
        shared
            .show(
                .init(
                    node: content().opaqueView(),
                    allowsBackgroundTap: allowsBackgroundTap,
                    action: action
                )
            )
    }

    public func dismiss() {
        stopTracking()
        toast = nil
        processQueue()
    }

	public static let shared = ToastPresenter()
}

private extension ToastPresenter {
    func processQueue() {
        guard !queue.isEmpty else { return }
		let next = queue.dequeue()
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
        // You only need to check ~1 per 60th of a second at most; higher accuracy is overkill for
        // toast durations.
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 1, maximum: 30, preferred: 10)
		link.add(to: .main, forMode: .tracking)
        displayLink = link
    }

    func stopTracking() {
        displayLink?.invalidate()
        displayLink = nil
        startTime = nil
    }

    @objc private func update(displayLink _: CADisplayLink) {
        guard let startTime, let toast else { return }
        elapsedTime = CACurrentMediaTime() - startTime
        if elapsedTime > toast.duration {
            dismiss()
        }
    }
}
