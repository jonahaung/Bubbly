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

	@Environment(MsgCellViewModel.self) private var viewModel
	@Environment(\.conversationTheme) private var theme
	private var layout: MsgCellLayout { viewModel.layout }

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
		.background(bubbleColor)
		.padding(
			.init(top: 0.1, leading: viewModel.isSender ? 0.5 : 0.2, bottom: 0.5, trailing: viewModel.isSender ? 0.2 : 0.5)
		)
		.background(theme.shadowColor)
		.foregroundStyle(viewModel.isSender ? theme.outgoingForegroundColor : theme.incomingForegroundColor)
		.containerShape(bubbleShape)
	}

	private var bubbleShape: UnevenRoundedRectangle {
		if bubbleCorner == .none {
			return .init()
		}
		return bubbleCorner.roundedRectange(cornerRadius: theme.bubbleCornorRadius)
	}
	private var bubbleColor: Color {
		viewModel.isSender ? theme.outgoingBubbleColor : theme.incomingBubbbleColor
	}

	private var bubbleCorner: BubbleCorner {
		let isSelected = layout.isSelected
		if isSelected {
			return .all
		}
//		var corner = bubble.bubbleCorner
//
//		if id == selected.previous?.id {
//			corner.append(.bottom)
//			return corner
//		}
//		if id == selected.next?.id {
//			corner.append(.top)
//			return corner
//		}
		return layout.bubble.bubbleCorner
	}
}
