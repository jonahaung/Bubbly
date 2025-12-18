//
//  MsgCellOutgoingStatusView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 31/8/25.
//

import Core
import Database
import Services
import SwiftUI

struct MsgCellOutgoingStatusView: View {

	@Environment(MsgCellViewModel.self) private var viewModel
	@Environment(\.conversation) private var conversation
	@Environment(\.namespace) private var namespace

	@ViewBuilder
	var body: some View {
		if viewModel.isSender {
			VStack(alignment: .leading, spacing: 1) {
				let seenMembers = seenMembers
				if seenMembers.isEmpty {
					MsgCellOutgoingStatus(msg: viewModel.msg)
				} else {
					ForEach(seenMembers) { seenMember in
						if let contact = ContactStore.shared.contact(
							for: seenMember.uid
						) {
							ProfilePhoto(contact, size: .custom(ChatLayoutConstants.Cell.defaultSpacing - 6))
								.if_let(namespace?.value) { value, view in
									view
										.matchedGeometryEffect(
											id: contact.uid,
											in: value
										)
								}

						}
					}
				}
			}
			.frame(width: ChatLayoutConstants.Cell.defaultSpacing - 4)
		}
	}

	private var seenMembers: [SeenMember] {
		conversation.properties.seenMembers.filter {
			$0.msgId == viewModel.id
		}
	}
}

struct MsgCellOutgoingStatus: View {
	let msg: Message

	var outgoingStatus: MsgOutgoingStatus {
		msg.outgoingStatus
			.contains(
				where: { $0.value == .sending
				}) ? .sending
		: .sent
	}

	var body: some View {
		Group {
			switch outgoingStatus {
			case .sending:
				Image(systemName: "progress.indicator")
					.resizable()
					.scaledToFit()
			case .sent:
				EmptyView()
			case .sendingFailed:
				Image(systemName: "exclamationmark.octagon.fill")
					.resizable()
					.scaledToFit()
			}
		}
		.foregroundStyle(.secondary)
		.padding(.trailing, 2)
		.frame(square: 12)
		.equatable(by: outgoingStatus)
	}
}
