//
//  PressGestureViewModifier.swift
//  XUI
//
//  Created by Aung Ko Min on 24/10/25.
//

import SwiftUI
import Combine

public struct PressGestureViewModifier: ViewModifier {
	@GestureState private var startTimestamp: Date?
	@State private var timePublisher: Publishers.Autoconnect<Timer.TimerPublisher>
	private var onPressing: (TimeInterval) -> Void
	private var onEnded: () -> Void

	private let displayLink = DisplayLink()

	public init(interval: TimeInterval = 0.016, onPressing: @escaping (TimeInterval) -> Void, onEnded: @escaping () -> Void) {
		_timePublisher = State(wrappedValue: Timer.publish(every: interval, tolerance: nil, on: .current, in: .common).autoconnect())
		self.onPressing = onPressing
		self.onEnded = onEnded
	}

	public func body(content: Content) -> some View {
		content
			.gesture(
				DragGesture(minimumDistance: 0, coordinateSpace: .local)
					.onChanged { _ in
						startDisplayLinkIfNeeded()
					}
					.onEnded { _ in
						stopDisplayLinkIfNeeded()
					}
//					.updating($startTimestamp, body: { _, current, _ in
//						if current == nil {
//							current = Date()
//						}
//					})
//					.onEnded { _ in
//						onEnded()
//					}
			)
			.onReceive(timePublisher, perform: { timer in
				if let startTimestamp = startTimestamp {
					let duration = timer.timeIntervalSince(startTimestamp)
					onPressing(duration)
				}
			})
	}

	private func startDisplayLinkIfNeeded() {
		guard displayLink.state == .inactive else {
			return
		}
		displayLink.onUpdate = onUpdate(_:)
		displayLink.onTargetReached = onTargetReached(_:)
		displayLink.start()
	}
	private func stopDisplayLinkIfNeeded() {
		guard displayLink.state == .running else {
			return
		}
		displayLink.stop()
	}
	private func onUpdate(_ time: Double) {
		print(time)
	}
	private func onTargetReached(_ time: Double) {

	}
}

public extension View {
	func onPress(interval: TimeInterval = 0.016, onPressing: @escaping (TimeInterval) -> Void, onEnded: @escaping () -> Void) -> some View {
		modifier(PressGestureViewModifier(interval: interval, onPressing: onPressing, onEnded: onEnded))
	}
}
