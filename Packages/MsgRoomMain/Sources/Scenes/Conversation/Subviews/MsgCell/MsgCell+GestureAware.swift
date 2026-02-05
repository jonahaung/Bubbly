//
//  MsgCell+GestureAware.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 19/9/25.
//

import Database
import Services
import SwiftUI
import XUI

private enum MsgCellGestureThresholds {
	static let dragMinDistance: CGFloat = 80
	static let markTrigger: CGFloat = 170
}

extension MsgCell {

	@Observable
	final class GestureViewModel {
		var draggedOffset: CGFloat = .zero
		@ObservationIgnored
		var draggedLimitReached = false
		var isLongPressActive = false

		// For throttling drag updates
		@ObservationIgnored
		var lastAppliedOffset: CGFloat = .zero
	}

	struct GestureAware<Content: View>: View {

		@Environment(MsgCellViewModel.self) private var viewModel
		@Environment(\.msgCellActions) private var sendMsgCellInteraction
		@State private var model = GestureViewModel()

		let content: () -> Content

		var body: some View {
			content()
				// Clamp to integral pixels to reduce re-rasterization jitter
				.offset(x: round(model.draggedOffset))
				// Prefer a simpler gesture composition: prioritize drag, add tap separately
				.highPriorityGesture(dragGesture, including: .gesture)
				.simultaneousGesture(tapGesture)
				// Use a minimal overlay only while measuring; avoid .background
				.overlay(alignment: .topLeading) {
					if model.isLongPressActive {
						Color.clear
							// Keep this view as light as possible
							.allowsHitTesting(false)
							.accessibilityHidden(true)
							// One-shot geometry read: capture and immediately dismiss
							.onGeometryChange(for: CGRect.self) { proxy in
								proxy.frame(in: .global)
							} action: { newFrame in
								// Immediately turn off the overlay to avoid extra passes
								model.isLongPressActive = false
								Haptics.play(.rigid, 0.7)
								withTransaction(.withoutAnimation) {
									sendMsgCellInteraction?(
										.onFocusMsgBubble(.init(id: viewModel.id, frame: newFrame))
									)
								}
							}
					}
				}
				.onPressingChanged(in: .local) { _ in
					// Start measuring only if not already active to avoid re-entrancy
					if !model.isLongPressActive {
						// Defer to next runloop to avoid changing the layer tree
						// in the same frame as the gesture state change.
						DispatchQueue.main.async {
							model.isLongPressActive = true
						}
					}
				}
		}
	}
}

extension MsgCell.GestureAware {
	private var tapGesture: some Gesture {
		TapGesture(count: 2)
			.onEnded { _ in
				sendMsgCellInteraction?(.onTapMsg(viewModel.id))
			}
	}

	private var dragGesture: some Gesture {
		DragGesture(minimumDistance: MsgCellGestureThresholds.dragMinDistance, coordinateSpace: .local)
			.onChanged { value in
				let width = value.translation.width

				// Only allow dragging in the intended direction
				let validDirection = viewModel.isSender
					? (width < -MsgCellGestureThresholds.dragMinDistance)
					: (width > MsgCellGestureThresholds.dragMinDistance)

				guard validDirection else {
					// Prevent drift in the wrong direction
					if !model.draggedLimitReached {
						model.draggedOffset = 0
						model.lastAppliedOffset = 0
					}
					return
				}

				let absWidth = abs(width)

				// Trigger once when passing the mark threshold
				if !model.draggedLimitReached, absWidth > MsgCellGestureThresholds.markTrigger {
					model.draggedLimitReached = true
					sendMsgCellInteraction?(.onMarkMsg(viewModel.msg))
				}

				// Stop updating offset after limit reached to avoid jitter
				guard !model.draggedLimitReached else { return }

				// Throttle updates: apply only if change > 1pt and clamp to integral pixels
				let clamped = round(width)
				if abs(clamped - model.lastAppliedOffset) >= 1 {
					model.draggedOffset = clamped
					model.lastAppliedOffset = clamped
				}
			}
			.onEnded { _ in
				model.draggedLimitReached = false
				guard model.draggedOffset != 0 else { return }
				withTransaction(.init(animation: .interactiveSpring)) {
					model.draggedOffset = 0
					model.lastAppliedOffset = 0
				}
			}
	}
}
