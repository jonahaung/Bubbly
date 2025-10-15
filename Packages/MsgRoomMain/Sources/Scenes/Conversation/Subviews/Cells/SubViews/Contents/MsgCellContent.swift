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

struct MsgCellContent: View {

	let bubbleCorner: BubbleCorner
	@Environment(MsgCellViewModel.self) private var viewModel
	@Environment(\.conversation) private var conversation
	
	var body: some View {
		ZStack {
			switch viewModel.displayData.content {
			case .text(let text):
				bubbleView()
				TextContent(text: text)
					.background(color)
					.padding(.horizontal, conversation.theme.bubblePadding)
					.padding(.vertical, conversation.theme.bubblePadding/2)
					.foregroundStyle(viewModel.foregroundStyle)
					.layoutPriority(1)
			case .markdown(let elements):
				MarkdownContent(text: viewModel.msg.text, elements: elements)
			case .attachment(let attachment):
				AttachmentContent(attachment: attachment)
					.frame(size: attachment.bestFitSize)
					.equatable(by: attachment)
					.clipShape(bubbleShape)
			case .emoji(let image):
				Text(image)
			}
		}
	}
	private var bubbleShape: BubbleShape { .init(corner: bubbleCorner, cornerRadius: conversation.theme.bubbleCornorRadius)}
	private var color: Color {
		viewModel.isSender ? conversation.theme.outgoingBubbleColor : conversation.theme.incomingBubbleColor
	}
	private func bubbleView() -> some View {
		color
			.clipShape(bubbleShape)
			.shadow(color: conversation.theme.shadowColor, radius: 0.5, x: viewModel.isSender ? -0.5 : 0.5, y: 0.5)
			.padding(.bottom, 0.5)
	}
}
