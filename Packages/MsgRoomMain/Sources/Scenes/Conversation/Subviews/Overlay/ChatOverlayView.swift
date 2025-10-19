//
//  MsgsScrollViewOverlay.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 23/10/24.
//

import SwiftUI
import XUI
import Database
import Services
import UIKit

struct ChatOverlayView: View {

	let item: ChatOverlayView.Item
	@Environment(ChatViewManager.self) private var manager

	@ViewBuilder
	var body: some View {
		if let viewModel = manager.cellItems.viewModel(of: item.id) {
			ZStack {
				BlurredBackgroundView {
					manager.eventsManager.updateFocusedFrame(nil)
				}
				MsgCellContent(
					bubbleCorner: manager.msgCellLayoutFor(viewModel.msg).bubble.bubbleCorner
				)
				.frame(size: item.frame.size)
				.position(.init(x: item.frame.midX, y: item.frame.midY))

				RoomFocesedOverlayBar()
					.position(x: item.frame.midX, y: item.frame.minY)
			}
			.statusBarHidden()
			.environment(viewModel)
		}
	}
}

struct RoomFocesedOverlayBar: View {
	@Environment(ChatViewManager.self) private var manager
	@Environment(\.invokeMsgRoomAction) private var msgRoomAction
	@Environment(MsgCellViewModel.self) private var item

	var body: some View {
		HStack {
			SystemImageWithShape(.heartFill, .circle(.color(.pink)))
			Button {
				let msg = item.msg
				msgRoomAction?(.deleteMsg(rMsg: RMsg(msg)))
				manager.eventsManager.updateFocusedFrame(nil)
			} label: {
				SystemImageWithShape(.trashFill, .circle(.color(.red)))
			}
			SystemImageWithShape(.arrowshapeTurnUpLeftFill, .circle(.color(.indigo)))

			SystemImageWithShape(.arrowshapeTurnUpRightFill, .circle(.color(.blue)))
			SystemImageWithShape(.ellipsis, .circle(.color(.gray)))
				.presentSheet {
					Text(item.msg.preetyPrinted)
				}
		}
	}
}
struct BlurredBackgroundView: View {
	@Environment(ChatViewManager.self) private var manager
	var tapAction: (() -> Void)?

	var body: some View {
		manager.conversation.theme.background.color.opacity(0.9)
			.edgesIgnoringSafeArea(.all)
			.onTapGesture {
				tapAction?()
			}
	}
}
