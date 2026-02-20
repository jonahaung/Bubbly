import PhotosUI
import Services
import SwiftUI
import XUI

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
				switch composer.source {
				case .menu:
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
				case .liary:
					ComposeBarSourceButton(source: .text)
					photoPickerButton()
					Text(composer.photoPicker.selectedImages.count.description + " photos")
						.flexible(.horizontal)
				default:
					ComposeBarSourceButton(source: composer.source)
				}
				ComposeBarInputTextField(composer: composer)
				ComposeBarSendButton()
			}
			.animation(.interactiveSpring, value: composer.source)
			.padding(.init(top: 0, leading: 8, bottom: 0, trailing: 8))
		}
		.ignoresSafeArea(.container, edges: .bottom)
		.equatable(by: composer.source)
	}

	private func photoPickerButton() -> some View {
		Button {
			Router.shared
				.presnetModel(
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

private extension ComposeBar {
	struct EmojiPanel: View {
		@Environment(ChatComposer.self) private var composer

		var body: some View {
			EmojiPicker { emoji in
				composer.inputText.text.append(emoji.value)
			}
			.background(.regularMaterial, ignoresSafeAreaEdges: .bottom)
		}
	}
}
