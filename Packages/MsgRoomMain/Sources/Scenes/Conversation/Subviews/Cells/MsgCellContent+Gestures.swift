//
//  MsgCellContentGesturesHandlingView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 19/9/25.
//

import SwiftUI
import XUI
import Database
import Services

struct MsgCellContentGesturesView<Content: View>: View {

	@ViewBuilder var msgCellContent: () -> Content

	@Environment(MsgCellViewModel.self) private var viewModel
	@Environment(ChatViewManager.self) private var manager
	@Environment(\.sendMsgCellInteraction) private var sendMsgCellInteraction
	@Environment(\.conversation) private var conversation
	@State private var draggedLimitReached = false
	@State private var draggedOffset: CGFloat =  .zero

	var body: some View {
		msgCellContent()
//			.offset(x: draggedOffset)
			.background {
				if viewModel.canObserveFocusedFrame {
					Color.clear
						.hidden()
						.onGeometryChange(
							for: CGRect.self,
							of: { proxy in
								proxy.frame(in: .global)
							},
							action: {
								oldValue,
								newValue in
								Task { @MainActor in
									viewModel.canObserveFocusedFrame = false
									sendMsgCellInteraction?(
										.onFocusMsgBubble(
											.init(id: viewModel.id, frame: newValue)
										)
									)
								}
							})
				}
			}
//			.gesture(dragGesture, isEnabled: manager.scrollManager.isScrollingStopped)
	}
}

private extension MsgCellContentGesturesView {
	private var dragGesture: some Gesture {
		DragGesture(minimumDistance: 50, coordinateSpace: .local)
			.onChanged { value in
				print(value.translation.width)
				let width = value.translation.width.rounded(.towardZero)
				let isValid = viewModel.isSender ? width < 0 : width > 0
				guard isValid else { return }
				let absWidth = abs(width)
				if !draggedLimitReached && absWidth > 170 {
					draggedLimitReached = true
					sendMsgCellInteraction?(.onMarkMsg(viewModel.msg))
				}
				guard !draggedLimitReached else { return }
				draggedOffset = width
			}
			.onEnded { _ in
				draggedLimitReached = false
				guard draggedOffset != 0 else { return }
				withAnimation(.interactiveSpring) {
					draggedOffset = 0
				} completion: {
					Haptics.play(.soft, 0.5)
				}
			}
	}
}
import Combine

public struct PressGestureViewModifier: ViewModifier {
	@GestureState private var startTimestamp: Date?
	@State private var timePublisher: Publishers.Autoconnect<Timer.TimerPublisher>
	private var onPressing: (TimeInterval) -> Void
	private var onEnded: () -> Void

	public init(interval: TimeInterval = 0.016, onPressing: @escaping (TimeInterval) -> Void, onEnded: @escaping () -> Void) {
		_timePublisher = State(wrappedValue: Timer.publish(every: interval, tolerance: nil, on: .current, in: .common).autoconnect())
		self.onPressing = onPressing
		self.onEnded = onEnded
	}

	public func body(content: Content) -> some View {
		content
			.gesture(
				DragGesture(minimumDistance: 0, coordinateSpace: .local)
					.updating($startTimestamp, body: { _, current, _ in
						if current == nil {
							current = Date()
						}
					})
					.onEnded { _ in
						onEnded()
					}
			)
			.onReceive(timePublisher, perform: { timer in
				if let startTimestamp = startTimestamp {
					let duration = timer.timeIntervalSince(startTimestamp)
					onPressing(duration)
				}
			})
	}
}

public extension View {
	func onPress(interval: TimeInterval = 0.016, onPressing: @escaping (TimeInterval) -> Void, onEnded: @escaping () -> Void) -> some View {
		modifier(PressGestureViewModifier(interval: interval, onPressing: onPressing, onEnded: onEnded))
	}
}
