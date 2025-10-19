//
//  MsgCell.swift
//  Msgr
//
//  Created by Aung Ko Min on 22/10/22.
//

import SwiftUI
import XUI
import Database
import Services
import Core

struct MsgCell: View {

	let viewModel: MsgCellViewModel
	let bubble: Bubble
	@Environment(\.sendMsgCellInteraction) private var sendMsgCellInteraction
	@Environment(\.eventsManager) private var eventsManager

	var body: some View {
		HStack(alignment: .bottom, spacing: 0) {
			leftView()
			MsgCellContentGesturesView {
				MsgCellContent(bubbleCorner: bubbleCorner)
			}
			MsgCellOutgoingStatusView()
		}
		.environment(viewModel)
		.id(viewModel.id)
		.layoutValue(viewModel.msg.layoutValue)
	}

	private var bubbleCorner: BubbleCorner {
		guard let selected = eventsManager?.selectedMsg else {
			return bubble.bubbleCorner
		}
		let id = viewModel.id
		if id == selected.id {
			return .all
		}
		var corner = bubble.bubbleCorner

		if id == selected.previous?.id {
			corner.append(.bottom)
			return corner
		}
		if id == selected.next?.id {
			corner.append(.top)
			return corner
		}
		return corner
	}
	@ViewBuilder
	private func leftView() -> some View {
		if !viewModel.isSender {
			ZStack(alignment: .bottom) {
				if bubble.showAvatar, let sender = viewModel.sender() {
					ProfilePhoto(
						sender,
						size: .custom(ChatLayoutConstants.Cell.defaultSpacing),
						tapAction: .custom{
							sendMsgCellInteraction?(.onTapAvatar(viewModel.id))
						}
					)
					.equatable(by: sender.uid)
				}
			}
			.frame(width: ChatLayoutConstants.Cell.defaultSpacing + 4)
		}
	}
}
