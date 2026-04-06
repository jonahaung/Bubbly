#if os(iOS)
//
//  ComposerSourceButton.swift
//  Conversation
//
//  Created by Aung Ko Min on 5/4/26.
//


import Services
import SwiftUI
import XUI

struct ComposerSourceButton: View {

	let source: ChatComposer.Source
	@Environment(ChatComposer.self) private var composer

	var body: some View {
		CustomButton {
			composer.updateSource(source)
		} label: {
			Image(systemName: source.systemImageName)
				.resizable()
				.scaledToFit()
				.frame(square: 20)
				.symbolRenderingMode(.multicolor)
				.padding()
				.frame(square: 38)
				.background(.windowBackground, in: .circle)
		} onFinished: {
			action()
		}
	}
}
extension ComposerSourceButton {
	private func action() {
		@Bindable var composer = self.composer
		switch source {
		case .camera:
			Router.shared
				.presentModel(
					NavPath
						.view(
							node: CameraPicker { pickedItem in
								switch pickedItem {
								case let pickedItem as ImageCameraPickerItem:
									Task { @MainActor in
										await composer
											.parseImages(
												selectedImages: [
													.init(
														id: pickedItem.id.uuidString,
														image: pickedItem
															.underlyingMediaType
													)
												]
											)
									}
								case let pickedItem as MovieCameraPickerItem:
									print(pickedItem)
								default:
									break
								}
							}
							.opaqueView()
						)
				)
		case .liary:
			Router.shared
				.presentModel(
					NavPath
						.view(
							node: PhotoPickerView().environment(composer.photoPicker)
								.opaqueView()
						)
				)
		case .audio:
			break
		case .document:
			Router.shared
				.presentModel(
					NavPath
						.view(
							node: DocumentPicker(fileContent: $composer.fileContent)
								.environment(composer.photoPicker)
								.opaqueView()
						)
				)
		case .machineImag:
			Router.shared
				.presentModel(
					NavPath
						.view(
							node: TextEditor(text: $composer.fileContent).opaqueView()
						)
				)
		case .emoji:
			break
		}
	}
}

#endif
