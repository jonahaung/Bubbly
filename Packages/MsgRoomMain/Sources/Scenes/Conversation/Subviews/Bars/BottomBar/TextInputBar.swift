//
//  ChatInputBarTextView.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 26/6/24.
//

//
//  TextInputBar.swift
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

struct TextInputBar: View {

	@Environment(ChatViewManager.self) private var manager
	@Environment(ChatInputBarManager.self) private var inputManager
	@Environment(\.sendChatRoomAction) private var msgRoomAction
	@Environment(\.focusState) private var focusState
	@Environment(\.screenSize) private var screenSize

	var body: some View {
		HStack(alignment: .bottom, spacing: 8) {

			// MARK: Image Picker Button
			PhotosPicker(
				selection: .init(
					get: { inputManager.imagePicker.photoPickerItems },
					set: { inputManager.imagePicker.photoPickerItems = $0 }
				),
				matching: .images
			) {
				Image(systemName: "plus")
					.font(.headline)
					.frame(width: 35, height: 35)
					.foregroundStyle(.white)
					.background(Color.accentColor.gradient, in: .circle)
			}

			// MARK: Debounced Text Field
			ChatTextField(
				text: .constant(inputManager.text)
			) { newValue in
				inputManager.text = newValue
			}
			.scrollDisabled(true)
			.layoutPriority(5)
			.frame(minHeight: 35)
			.geometryGroup()

			AsyncButton {
				await sendButtonPressed()
			} label: { _ in
				Image(systemSymbol: .arrowshapeUpFill)
					.font(.headline)
					.foregroundStyle(.white)
					.frame(square: 35)
					.background(Color.accentColor.gradient, in: .circle)
			}
		}
		.padding(.horizontal, 12)
		.padding(.bottom, 8)
		.frame(width: screenSize.width, alignment: .bottom)
	}

	private func sendButtonPressed() async {
		inputManager.send(conversation: manager.conversation)
	}
}
