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
	@Bindable var inputManager: ChatInputBarManager
	@Environment(\.currentUser) private var currentUser
	@Environment(\.sendChatRoomAction) private var msgRoomAction
	@Environment(\.focusState) private var focusState

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
			if let focused = focusState?.value {
				TextField("Text ..", text: $inputManager.text, axis: .vertical)
					.focused(focused)
					.lineLimit(30)
					.autocorrectionDisabled(true)
					.padding(6)
					.padding(.horizontal, 8)
					.lineSpacing(1.4)
					.textScale(.default)
					.textFieldStyle(.automatic)
					.layoutPriority(2)
					.keyboardType(.twitter)
					.font(.callout)
					.allowsTightening(true)
					.equatable(by: inputManager.text)
			}

			AsyncButton {
				await sendButtonPressed()
			} label: {
				Image(systemSymbol: .arrowshapeUpFill)
					.font(.headline)
					.foregroundStyle(Color.white.gradient)
					.padding(10)
					.background(Color.accentColor.gradient, in: .circle)
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
		}
		.padding(.horizontal, 8)
		.padding(.bottom, 4)

	}

	private func sendButtonPressed() async {
		inputManager.send(conversation: manager.conversation)
	}
}
