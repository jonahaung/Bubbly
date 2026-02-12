//
//  MsgCellAction.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 12/7/25.
//

import Database
import SwiftUI

struct MsgCellAction {
	enum ActionType {
		case onTapMsg(String)
		case onMarkMsg(Message)
		case onTapAvatar(String)
		case onFocusMsgBubble(_ item: ChatOverlayView.Item?)
		case onUploadedAttachments(Message)
		case onReact(Message, ReactionType)
	}

	let action: (ActionType) -> Void
	func callAsFunction(_ type: ActionType) {
		action(type)
	}
}

extension EnvironmentValues {
	@Entry var msgCellActions: MsgCellAction?
}
