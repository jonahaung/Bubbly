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

			Row(alignment: .bottom, spacing: -8) {
				if composer.source == .menu {
					ComposeBarSourceButton(source: .camera)
					PhotosPicker(
						selection: composer.photoPicker.photoPickerItems,
						maxSelectionCount: 5,
						selectionBehavior: .continuousAndOrdered,
						preferredItemEncoding: .automatic,
						photoLibrary: .shared()
					) {
						Image(systemName: "photo.on.rectangle.angled")
							.resizable()
							.scaledToFit()
							.frame(width: 24, height: 24)
							.foregroundStyle(AngularGradient(
								gradient: Gradient(
									colors:[.blue, .accentColor]
								),
								center: .center
							))
					}
					.photosPickerStyle(.presentation)
					.frame(square: 44)
					.background(.windowBackground, in: .circle)

					Spacer(minLength: 32)
					ComposeBarSourceButton(source: .audio)
					ComposeBarSourceButton(source: .machineImag)
					ComposeBarSourceButton(source: .emoji)
				} else {
					ComposeBarSourceButton(source: composer.source)
				}
				Spacer(minLength: 17)
				ComposeBarInputTextField(composer: composer)
				ComposeBarSendButton()
			}
			.fontDesign(.rounded)
			.geometryGroup()
		}
		.sensoryFeedback(
			.impact(weight: .light, intensity: 0.7),
			trigger: composer.source
		)
		.animation(.interactiveSpring, value: composer.source)
		.animation(.interactiveSpring, value: composer.hasContent)
		.ignoresSafeArea(.container, edges: .bottom)
	}
}

private extension ComposeBar {
	struct Row<Content: View>: View {
		var alignment: VerticalAlignment = .bottom
		var spacing: CGFloat = 0
		@ViewBuilder var content: () -> Content

		var body: some View {
			HStack(alignment: alignment, spacing: spacing) {
				content()
			}
			.padding(.init(top: 0, leading: 8, bottom: 4, trailing: 8))
		}
	}

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
