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
import Core

struct ChatOverlayView: View {

	let item: ChatOverlayView.Item
	let viewModel: MsgCellViewModel
	@Environment(ChatViewManager.self) private var manager
	var body: some View {
		ZStack {
			BlurredBackgroundView {
				manager.eventsManager.updateFocusedFrame(nil)
			}
			MsgCellContent()
				.frame(size: item.frame.size)
				.position(x: item.frame.midX, y: item.frame.midY)

			RoomFocesedOverlayBar()
				.position(x: item.frame.midX, y: item.frame.minY)
		}
		.statusBarHidden()
		.environment(viewModel)
	}
}

struct RoomFocesedOverlayBar: View {
	@Environment(ChatViewManager.self) private var manager
	@Environment(\.sendChatRoomAction) private var msgRoomAction
	@Environment(MsgCellViewModel.self) private var item

	var body: some View {
		HStack {
			SystemImageWithShape(.heartFill, .circle(.color(.pink)))
			AsyncButton {
				let msg = await item.msg
				await msgRoomAction?(.deleteMsg(rMsg: RMsg(msg)))
				await manager.eventsManager.updateFocusedFrame(nil)
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
