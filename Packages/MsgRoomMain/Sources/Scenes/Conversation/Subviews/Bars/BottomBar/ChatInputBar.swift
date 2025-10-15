//
//  ChatInputBar.swift
//  Msgr
//
//  Created by Aung Ko Min on 21/10/22.
//

import SwiftUI
import XUI
import MediaPicker
import PhotosUI
import Core
import Database

struct ChatInputBar: View {

	@State private var inputManager = ChatInputBarManager()
	@Environment(ChatViewManager.self) private var manager

	var body: some View {
		VStack(spacing: 0) {
			if inputManager.imagePicker.selections.isEmpty == false {
				imageAttachmentView
			}
			TextInputBar(inputManager: inputManager)
				.padding(.top, 4)
				.background {
					manager.conversation.theme.background.color.ignoresSafeArea(edges: .bottom)
				}
		}
		.environment(inputManager)
	}

	private var imageAttachmentView: some View {
		ScrollView(.horizontal) {
			HStack {
				ForEach(inputManager.imagePicker.selections) { selectedPhoto in
					Group {
						if let processedPhoto = inputManager.imagePicker.processedPhotos[selectedPhoto.id] {
							Button {
								inputManager.send(conversation: manager.conversation)
							} label: {
								Image(uiImage: processedPhoto)
									.resizable()
									.scaledToFill()
									.aspectRatio(1, contentMode: .fill)
							}

						} else {
							ZStack {
								ProgressView()
									.controlSize(.mini)
							}
							.frame(square: 150)
							.task { [self] in
								await inputManager.imagePicker.loadPhoto(selectedPhoto)
							}
						}
					}
					.frame(maxHeight: 70)
				}
				Button("Remove All") {
					inputManager.imagePicker.selections.removeAll()
				}
			}
			.padding(.horizontal, 8)
		}
	}
}
