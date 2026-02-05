//
//  MsgCell+Header.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 31/12/25.
//

import Core
import Database
import Services
import SwiftUI
import XUI

extension MsgCell {
	struct Header: View {
		@Environment(MsgCellViewModel.self) private var viewModel
		private var msg: Message { viewModel.msg }
		@Environment(\.typography) private var typography

		private var headerText: String {
			if msg.isSender {
				return msg.date.formatted(date: .abbreviated, time: .shortened)
			} else {
				let name: String? = ContactStore.shared.contact(for: msg.senderID)?.name
				return name ?? "Unknown"
			}
		}

		var body: some View {
			let hPadding: CGFloat = ChatLayoutConstants.Cell.defaultSpacing + 4 + 8
			Text(headerText)
				.font(typography.caption1)
				.padding(.horizontal, hPadding)
		}
	}
}
