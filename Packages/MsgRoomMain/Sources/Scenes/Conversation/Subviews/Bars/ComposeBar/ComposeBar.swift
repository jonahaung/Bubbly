//
//  ChatComposerBar.swift
//  Msgr
//
//  Created by Aung Ko Min on 21/10/22.
//

import SwiftUI
import XUI
import PhotosUI

struct ComposeBar: View {

	let composer: ChatComposer
	@Environment(\.conversationTheme) private var theme
	var body: some View {
		VStack(spacing: 0) {
			switch composer.source {
			case .emoji:
				EmojiPanel()
			default:
				if !composer.attachments.isEmpty {
					ComposeBarAttachmentView()
				}
			}
			HStack(alignment: .bottom, spacing: 4) {
				if composer.source == .menu {
					HStack(alignment: .center, spacing: -8) {
						ComposeBarSourceButton(source: .camera)
						PhotosPicker(
							selection: composer.photoPicker.photoPickerItems,
							maxSelectionCount: 5,
							selectionBehavior: .continuousAndOrdered,
							preferredItemEncoding: .automatic,
							photoLibrary: .shared()
						) {
							Image(systemName: ChatComposer.Source.liary.systemImageName)
								.resizable()
								.scaledToFit()
								.frame(width: 20, height: 20)
						}
						.photosPickerStyle(.presentation)
						.frame(square: 38)
						.foregroundStyle(
							ChatComposer.Source.liary.foreGroundStyle
						)
						.background(.windowBackground, in: .circle)

						ComposeBarSourceButton(source: .audio)
					}
					.frame(height: 44)

					HStack(alignment: .center, spacing: -8) {
						ComposeBarSourceButton(source: .machineImag)
						ComposeBarSourceButton(source: .emoji)
					}
					.frame(height: 44)
				} else {
					HStack(alignment: .center) {
						ComposeBarSourceButton(source: composer.source)
					}
					.frame(height: 44)
				}
				ComposeBarInputTextField(composer: composer)
				ComposeBarSendButton()
			}
			.padding(.init(top: 0, leading: 8, bottom: 4, trailing: 8))
		}
		.sensoryFeedback(
			.impact(weight: .light, intensity: 0.7),
			trigger: composer.source
		)
		.ignoresSafeArea(.container, edges: .bottom)
	}
}

private extension ComposeBar {
	struct EmojiPanel: View {
		@Environment(ChatComposer.self) private var composer: ChatComposer

		var body: some View {
			EmojiPicker { emoji in
				composer.inputText.text.append(emoji.value)
				composer.inputText.selectAll()
				composer.source = .text
			}
			.background(.regularMaterial, ignoresSafeAreaEdges: .bottom)
		}
	}
}
