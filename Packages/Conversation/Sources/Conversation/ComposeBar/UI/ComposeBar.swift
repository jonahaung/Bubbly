//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import PhotosUI
import Services
import SwiftUI
import XUI

struct ComposeBar: View {

	@State private var viewModel = ComposeBarViewModel()
	@Environment(ChatComposer.self) private var composer
	@Environment(\.sharedFocusState) private var focusState
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
				HamburgerButton(isOpen: $viewModel.isMenuOpened, size: 38) { newValue in
					if newValue {
						focusState?.defocus()
					}
				}
				if viewModel.isMenuOpened {
					switch composer.source {
					case .liary:
						ComposeBarSourceButton(source: .text)
						photoPickerButton()
						Text(composer.photoPicker.selectedImages.count.description + " photos")
							.flexible(.horizontal)
					default:
						HStack(alignment: .center, spacing: -8) {
							ComposeBarSourceButton(source: .camera)

							photoPickerButton()
							ComposeBarSourceButton(source: .audio)
						}
						.frame(height: 44)

						HStack(alignment: .center, spacing: -8) {
							ComposeBarSourceButton(source: .machineImag)
							ComposeBarSourceButton(source: .emoji)
						}
						.frame(height: 44)
					}
				}
				ComposeBarInputTextField(composer: composer)
				ComposeBarSendButton()
			}
			.animation(.easeInExponential, value: viewModel.isMenuOpened)
			.padding(.init(top: 0, leading: 16, bottom: 4, trailing: 16))
		}
		.background(
			LinearGradient(
				colors: [
					.clear,
					theme.backgroundColor
				],
				startPoint: .top,
				endPoint: .bottom
			)
		)

	}

	private func photoPickerButton() -> some View {
		Button {
			Router.shared
				.presentModel(
					NavPath.view(PhotoPickerView().environment(composer.photoPicker).opaqueView())
				)
		} label: {
			Image(systemName: ChatComposer.Source.liary.systemImageName)
				.resizable()
				.frame(square: 20)
				.foregroundStyle(ChatComposer.Source.liary.foreGroundStyle)
		}
		.frame(square: 38)
		.background(.windowBackground, in: .circle)
	}
}

extension ComposeBar {
	fileprivate struct EmojiPanel: View {
		@Environment(ChatComposer.self) private var composer

		var body: some View {
			EmojiPicker { emoji in
				composer.inputText.text.append(emoji.value)
			}
			.background(.regularMaterial, ignoresSafeAreaEdges: .bottom)
		}
	}
}
