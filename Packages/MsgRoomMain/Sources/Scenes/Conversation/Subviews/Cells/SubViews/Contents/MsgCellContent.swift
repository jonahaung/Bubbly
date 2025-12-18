//
//  MsgCellContent.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 1/7/24.
//

import Core
import Database
import Services
import SwiftUI
import XUI

struct MsgCellContent: View {
	@Environment(MsgCellViewModel.self) private var viewModel
	@Environment(\.conversationTheme) private var theme
	private var layout: MsgCellLayout { viewModel.layout }
	@Environment(\.selectedMsg) private var selectedMsg
	@Environment(\.conversationTheme) private var conversationTheme

	var body: some View {
		ZStack {
			switch viewModel.displayData.content {
			case let .text(text):
				if let attachment = viewModel.msg.attachment {
					VStack(alignment: .leading, spacing: 0) {
						TextContent(text: text)
							.layoutPriority(-1)
							.padding(theme.bubblePading)
						AttachmentContent(attachment: attachment)
							.frame(height: attachment.bestFitHeight)
					}
					.frame(width: attachment.bestFitWidth)
					.mask(ContainerRelativeShape().inset(by: 4))
				} else {
					TextContent(text: text)
						.padding(theme.bubblePading)
				}
			case let .markdown(attributedString):
				MarkdownTextContent(text: attributedString)
					.padding(theme.bubblePading)
			case let .attachment(attachment):
				AttachmentContent(attachment: attachment)
					.frame(size: attachment.bestFitSize)
					.clipShape(ContainerRelativeShape().inset(by: 3))
			case let .emoji(image):
				Text(image)
			}
		}
		.foregroundStyle(viewModel.isSender ? theme.outgoingForegroundColor : theme.incomingForegroundColor)
		.background(bubbleColor)
		.padding(
			.init(top: 0.2, leading: viewModel.isSender ? 0.5 : 0.2, bottom: 0.5, trailing: viewModel.isSender ? 0.2 : 0.5)
		)
		.containerShape(bubbleShape)
		.background(bubbleShape.fill(theme.shadowColor))
	}

	private var bubbleShape: UnevenRoundedRectangle {
		bubbleCorner.roundedRectange(cornerRadius: theme.bubbleCornorRadius)
	}

	private var bubbleColor: Color {
		viewModel.isSender ? theme.outgoingBubbleColor : theme.incomingBubbbleColor
	}

	private var bubbleCorner: BubbleCorner {
		let isSelected = selectedMsg?.id == viewModel.id
		if isSelected {
			return .all
		}
		var corner = layout.bubble.bubbleCorner

		if selectedMsg?.previous == viewModel.id {
			corner.append(.bottom)
			return corner
		}
		if selectedMsg?.next == viewModel.id {
			corner.append(.top)
			return corner
		}
		return corner
	}
}
