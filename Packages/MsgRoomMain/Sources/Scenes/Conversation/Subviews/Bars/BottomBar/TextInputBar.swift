//
//  ChatInputBarTextView.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 26/6/24.
//

import SwiftUI
import XUI
import MediaPicker
import AVKit
import SFSafeSymbols
import Database
import Services
import PhotosUI

@MainActor
struct TextInputBar: View {

	@Environment(ChatViewManager.self) private var manager
	@State var inputManager: ChatInputBarManager
	@Environment(CurrentUser.self) private var currentUser
//	@FocusState private var textFieldIsFocused: Bool
	@Environment(\.invokeMsgRoomAction) private var msgRoomAction

	var body: some View {
		HStack(alignment: .bottom, spacing: 4) {
			ZStack(alignment: .bottomLeading) {
				var imageName: String { inputManager.imagePicker.selections.isEmpty ? "plus" : "\(inputManager.imagePicker.selections.count).circle.fill" }
				PhotosPicker(
					selection: $inputManager.imagePicker.photoPickerItems,
					matching: .images,
				) {
					Image(systemName: imageName)
						.font(.headline)
						.padding(8)
						.foregroundStyle(Color.white.gradient)
						.background(Color.accentColor.gradient, in: .circle)
				}
			}
			TextField("Text ..", text: $inputManager.text, axis: .vertical)
				.lineLimit(30)
				.padding(6)
				.padding(.horizontal, 8)
//				.focused($textFieldIsFocused)
				.lineSpacing(1.4)
				.textScale(.default)
				.textFieldStyle(.plain)
				.layoutPriority(2)
				.keyboardType(.twitter)
				.font(.callout)
				.allowsTightening(true)

			Button {
				sendButtonPressed()
			} label: {
				Image(systemSymbol: .arrowshapeUpFill)
					.font(.headline)
					.foregroundStyle(Color.white.gradient)
					.padding(10)
					.rotationEffect(
						inputManager.hasContent ?
							.degrees(0) : .degrees(-90)
					)
					.animation(
						.bouncy(
							extraBounce: 0.2
						),
						value: inputManager.text.isWhitespace
					)

			}
			.background(Color.accentColor.gradient, in: .circle)
		}
		.padding(.horizontal, 8)
		.padding(.bottom, 4)
	}
	private func sendButtonPressed() {
		Haptics.play(.medium, 0.9)
		inputManager.send(conversation: manager.conversation)
		
	}
}
