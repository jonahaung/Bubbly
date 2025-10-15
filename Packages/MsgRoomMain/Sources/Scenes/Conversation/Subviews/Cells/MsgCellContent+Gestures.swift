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
	@Environment(\.sendMsgCellInteraction) private var sendMsgCellInteraction
	@Environment(\.conversation) private var conversation
	@State private var longPressToFocus = false
	@State private var draggedOffset: CGFloat = 0
	@State private var draggedLimitReached = false

	var body: some View {
		msgCellContent()
			.transformEffect(.init(translationX: draggedOffset, y: 0))
			.gesture(gesture, including: .gesture)
			.background {
				if longPressToFocus {
					Color.clear
						.onGeometryChange(
							for: CGRect.self,
							of: { proxy in
								proxy.frame(in: .global)
							},
							action: {
								oldValue,
								newValue in
								longPressToFocus = false

								sendMsgCellInteraction?(
									.onFocusMsgBubble(
										.init(id: viewModel.id, frame: newValue)
									)
								)
							})
				}
			}
	}
}

private extension MsgCellContentGesturesView {
	var gesture: some Gesture {
		tapGesture
			.exclusively(before: longPressGesture
				.exclusively(before: dragGesture)
			)
	}
	var longPressGesture: some Gesture {
		LongPressGesture(minimumDuration: 0.4)
			.onEnded { pressed in
				longPressToFocus = true
			}
	}
	var tapGesture: some Gesture {
		TapGesture(count: 2)
			.onEnded {
				sendMsgCellInteraction?(.onTapMsg(viewModel.id))
			}
	}
	private var dragGesture: some Gesture {
		DragGesture(minimumDistance: 100)
			.onChanged { value in
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
				withAnimation(.interactiveSpring) {
					draggedOffset = 0
				} completion: {
					Haptics.play(.soft, 0.5)
				}
			}
	}
}
