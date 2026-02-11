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
	struct Content: View, @MainActor Equatable {
		static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.viewModel.contentRenderKey == rhs.viewModel.contentRenderKey
		}

		let viewModel: MsgCellViewModel
		let theme: ConversationTheme
		let selectedMsg: SelectedMsg?
		@Environment(\.viewIsVisible) private var viewIsVisible

		var body: some View {
			let alignment = Alignment(
				horizontal: viewModel.horizontalAlignment.inverted,
				vertical: .top
			)
			ZStack(alignment: alignment) {
				StableBubbleView(
					viewModel: viewModel,
					theme: theme,
					selectedMsg: selectedMsg
				)
				.foregroundStyle(theme.foregroundStyle(for: viewModel.isSender))

				OverlayBubbleView(
					viewModel: viewModel,
					isVisible: viewIsVisible
				)
			}
			.font(theme.font)
		}
	}

	struct StableBubbleView: View, @MainActor Equatable {
		static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.renderKey == rhs.renderKey
		}

		let viewModel: MsgCellViewModel
		let theme: ConversationTheme
		let selectedMsg: SelectedMsg?

		private var renderKey: MsgCellViewModel.ContentRenderKey {
			viewModel.contentRenderKey
		}

		private var layout: MsgCellLayout {
			viewModel.layout
		}

		var body: some View {
			if !viewModel.msg.attachments.isEmpty {
				VStack(alignment: viewModel.horizontalAlignment, spacing: 0) {
					MsgAttachmentsView(
						attachments: viewModel.msg.attachments,
						alignment: viewModel.horizontalAlignment
					)

					if let text = viewModel.msg.text, !text.isWhitespace {
						TextContent(text: text)
					}
				}
			} else if let text = viewModel.msg.text {
				BubbleTextLayout {
					TextContent(text: text)
				}
				.padding(theme.bubblePading)
				.background {
					bubbleBackground
						.padding(
							.init(
								top: 0.2,
								leading: viewModel.isSender ? 1 : 0.2,
								bottom: 1,
								trailing: viewModel
									.isSender ? 0.2 : 1
							)
						)
						.background(
							theme.shadowColor(for: viewModel.isSender),
							in: .rect(corners: .concentric)
						)
				}
				.containerShape(bubbleShape)
			}
		}

		private var bubbleBackground: some View {
			ConcentricRectangle(corners: .concentric)
				.fill(theme.bubbleColor(for: viewModel.isSender))
		}

		private var bubbleShape: UnevenRoundedRectangle {
			computeBubbleCorner()
				.roundedRectange(cornerRadius: theme.bubbleCornerRadius)
		}

		private func computeBubbleCorner() -> BubbleCorner {
			if selectedMsg?.id == viewModel.id {
				return .all
			}
			var corner = layout.bubbleCorner
			if selectedMsg?.previous == viewModel.id { corner.append(.bottom) }
			if selectedMsg?.next == viewModel.id { corner.append(.top) }
			return corner
		}
	}

	struct OverlayBubbleView: View {
		let viewModel: MsgCellViewModel
		let isVisible: Bool

		var body: some View {
			if isVisible, !viewModel.msg.reactions.isEmpty {
				Reactions()
					.fixedSize()
					.allowsHitTesting(false)
			}
		}
	}
}
