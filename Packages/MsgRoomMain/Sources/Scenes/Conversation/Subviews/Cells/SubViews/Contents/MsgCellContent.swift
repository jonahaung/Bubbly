//
//  MsgCellContent.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 1/7/24.
//

import SwiftUI
import XUI
import Database
import Services
import Core

@MainActor
public final class ColorStorage {

	static let shared = ColorStorage()

	var incoming: Color = .blue
	var outgoing: Color = .blue


	func initialize(_ conversation: any ConversationRepresentable) {
		incoming = conversation.theme.incomingBubbleColor
		outgoing = conversation.theme.outgoingBubbleColor
	}
}

struct MsgCellContent: View {
	let bubbleCorner: BubbleCorner
	@Environment(MsgCellViewModel.self) private var viewModel
	@Environment(\.conversation) private var conversation

	var body: some View {
		ZStack(alignment: .center) {
			switch viewModel.displayData.content {
			case .text(let text):
				TextContent(text: text)
					.padding(.init(top: 6, leading: 12, bottom: 6, trailing: 10))
			case .markdown(let elements):
				MarkdownContent(text: viewModel.msg.text, elements: elements)
			case .attachment(let attachment):
				AttachmentContent(attachment: attachment)
					.clipShape(bubbleShape)
					.padding(
						.init(top: 0.1, leading: viewModel.isSender ? 0.5 : 0.2, bottom: 0.5, trailing: viewModel.isSender ? 0.2 : 0.5)
					)
			case .emoji(let image):
				Text(image)
			}
		}
		.background(color.opacity(1))
		.padding(
			.init(top: 0.1, leading: viewModel.isSender ? 0.5 : 0.2, bottom: 0.5, trailing: viewModel.isSender ? 0.2 : 0.5)
		)
		.background(Color.opaqueSeparator)
		.foregroundStyle(viewModel.foregroundStyle)
		.containerShape(bubbleShape)
		.compositingGroup()
	}

	private var bubbleShape: UnevenRoundedRectangle {
		bubbleCorner.roundedRectange(cornerRadius: conversation!.theme.bubbleCornorRadius)
	}
	private var color: Color {
		viewModel.isSender ? ColorStorage.shared.outgoing : ColorStorage.shared.incoming
	}
}
