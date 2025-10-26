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
			.offset(x: draggedOffset)
			.gesture(dragGesture, isEnabled: !viewModel.isSender)
	}
}

private extension MsgCellContentGesturesView {
	private var dragGesture: some Gesture {
		DragGesture(minimumDistance: 50, coordinateSpace: .local)
			.onChanged { value in
				let width = value.translation.width
				let isValid = viewModel.isSender ? width < -10 : width > 10
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
				withTransaction(.init(animation: .interactiveSpring)) {
					draggedOffset = 0
				}
				Haptics.play(.soft, 0.5)
			}
	}
}
