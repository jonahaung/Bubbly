//
//  MsgCell+Content.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 1/7/24.
//

import Core
import Database
import Services
import SwiftUI
import XUI

extension MsgCell {
	
	struct Content: View {
		@Environment(MsgCellViewModel.self) private var viewModel
		@Environment(\.conversationTheme) private var theme
		@Environment(\.selectedMsg) private var selectedMsg
		private var layout: MsgCellLayout { viewModel.layout }
		@Environment(\.viewIsVisible) private var viewIsVisible
		
		var body: some View {
			ZStack(alignment: .init(horizontal: viewModel.horizontalAlignment.inverted, vertical: .top)) {
				if !viewModel.msg.attachments.isEmpty {
					VStack(alignment: viewModel.horizontalAlignment, spacing: 0) {
						MsgAttachmentsView(
							attachments: viewModel.msg.attachments,
							alignment: viewModel.horizontalAlignment
						)
						
						if let text = viewModel.msg.text, !text.isWhitespace {
							TextContent(text: text)
								.padding(theme.bubblePading)
								.background(
									bubbleColor,
									in: RoundedRectangle(cornerRadius: theme.bubbleCornorRadius)
								)
						}
					}
					.equatable(by: viewModel.msg.attachments)
				} else {
					if let text = viewModel.msg.text {
						ZStack {
							ContainerRelativeShape.containerRelative
								.fill(bubbleColor)
								.padding(
									.init(
										top: 0.2,
										leading: viewModel.isSender ? 1 : 0.2,
										bottom: 1,
										trailing: viewModel
											.isSender ? 0.2 : 1)
								)
							TextContent(text: text)
								.padding(theme.bubblePading)
								.layoutPriority(1)
						}
						.background(shadowColor)
						.containerShape(bubbleShape)
					}
				}
				if !viewModel.msg.reactions.isEmpty {
					Reactions()
				}
			}
		}
		
		private var bubbleShape: UnevenRoundedRectangle {
			bubbleCorner.roundedRectange(cornerRadius: theme.bubbleCornorRadius)
		}
		
		private var bubbleColor: Color {
			viewModel.isSender ? theme.outgoingBubbleColor : theme.incomingBubbbleColor
		}
		private var shadowColor: Color {
			viewModel.isSender ? theme.outgoingShadowColor : theme.incomingShadowColor
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
}
