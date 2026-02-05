//
//  ComposeBar+SecondarySendButton.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 2/2/26.
//

import SwiftUI
import Database
import XUI

extension ComposeBar {
	struct ComposeBarSecondaryActionBar: View {

		@Environment(ChatComposer.self) private var composer: ChatComposer
		@Environment(\.conversation) private var conversation

		var body: some View {
			HStack(alignment: .bottom, spacing: 4) {
				ComposeBarBackButton(hasContent: composer.hasContent) {
					if composer.hasContent {
						composer.resetDraft()
					} else {
						composer.resetSource()
					}
				}

				Spacer()

				ComposeBarSourceTitle(text: composer.source.localizedName)

				Spacer()

				ComposeBarSecondaryActionButton(
					imageName: imageName,
					attachmentsCount: composer.attachments.count,
					inputPreview: composer.inputText.hasText ? composer.inputText.text : nil
				) {
					composer.handleSecondaryAction(conversation)
				}
			}
			.padding(.init(top: 0, leading: 8, bottom: 4, trailing: 8))
			.background(
				conversation.theme.background.color,
				ignoresSafeAreaEdges
				: .bottom)
		}
		var imageName: String {
			composer.hasContent ? "paperplane.fill" : "character.cursor.ibeam"
		}
	}
}

private struct ComposeBarBackButton: View {
	let hasContent: Bool
	let action: () -> Void

	var body: some View {
		Button(role: .cancel, action: action) {
			Image(systemName: hasContent ? "xmark" : "chevron.left")
		}
		.frame(square: 44)
		.background(.background, in: .circle)
	}
}

private struct ComposeBarSourceTitle: View {
	let text: String

	var body: some View {
		Text(text)
			.font(.callout.bold().smallCaps())
			.fontWidth(.compressed)
	}
}

private struct ComposeBarSecondaryActionButton: View {
	let imageName: String
	let attachmentsCount: Int
	let inputPreview: String?
	let action: () -> Void

	var body: some View {

		AsyncButton(
			options: [.disallowParallelOperations, .showAlertOnError, .showProgressViewOnLoading]
		) {
			action()
		} label: {
			Image(systemName: imageName)
				.resizable()
				.scaledToFit()
				.padding(10)
		}
		.frame(square: 44)
		.background(.background, in: .circle)
		.overlay(alignment: .topLeading) {
			if attachmentsCount > 0 {
				Image(systemName: "\(attachmentsCount).circle.fill")
					.resizable()
					.scaledToFit()
					.frame(square: 16)
					.foregroundStyle(Color.link.gradient)
			}
			if let inputPreview {
				Text(inputPreview)
			}
		}
	}
}
