//
//  ChatInputBar.swift
//  Msgr
//
//  Created by Aung Ko Min on 21/10/22.
//

import AVKit
import Database
import MediaPicker
import PhotosUI
import Services
import SFSafeSymbols
import SwiftUI
import XUI

struct ChatInputBar: View {

	@LazyState private var inputManager: ChatInputManager = ChatInputManager()
	@Environment(\.conversationTheme) private var theme
	@Environment(\.conversation) private var conversation
	@Environment(\.sendChatRoomAction) private var msgRoomAction
	@Environment(\.sharedFocus) private var sharedFocus

	var body: some View {
		VStack(spacing: 0) {
			VStack(spacing: 4) {
				if inputManager.imagePicker.selections.isEmpty == false {
					imageAttachmentView
				}
				if let linkPreview = inputManager.inputText.linkPreview {
					HStack {
						if let icon = linkPreview.image {
							AsyncImage(url: .init(string: icon)) { content in
								content.image?.resizable()
									.scaledToFit()
									.clipShape(RoundedRectangle(cornerRadius: 6))
							}
							.frame(maxWidth: 150)
						}
						if let title = linkPreview.title {
							Text(title)
								.font(.caption2)
						} else {
							Text(linkPreview.canonicalUrl)
						}
					}
					.font(.caption)
					.lineHeight(.tight)
				}
			}
			HStack(alignment: .bottom, spacing: 8) {
				PhotosPicker(selection: $inputManager.imagePicker.photoPickerItems, matching: .images) {
					Image(systemName: "plus")
						.font(.headline)
						.frame(width: 32, height: 32)
						.foregroundStyle(.white)
						.background(Color.accentColor.gradient, in: .circle)

				}
				TextField("Text ....", text: $inputManager.inputText.text, axis: .vertical)
					.lineLimit(1...10)
					.lineSpacing(1)
					.lineHeight(.leading(increase: 4))
					.baselineOffset(4)
					.if_let(sharedFocus) { sharedFocus, view in
						view.focused(sharedFocus.binding)
					}

				Button {
					inputManager.send(conversation: conversation)
				} label: {
					Image(systemSymbol: .arrowshapeUpFill)
						.font(.headline)
						.foregroundStyle(.white)
						.frame(square: 32)
						.background(Color.accentColor.gradient, in: .circle)

				}
			}
			.padding(8)
			.background(theme.backgroundColor, ignoresSafeAreaEdges: [.bottom, .leading, .trailing])
			.frame(maxWidth: .infinity)
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
								inputManager.send(conversation: conversation)
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
