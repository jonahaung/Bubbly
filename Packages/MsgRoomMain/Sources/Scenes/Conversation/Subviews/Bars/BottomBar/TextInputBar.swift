//
//  TextInputBar.swift
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

import AVKit
import Database
import MediaPicker
import PhotosUI
import SFSafeSymbols
import Services
import SwiftUI
import XUI

struct TextInputBar: View {
	@Environment(ChatViewManager.self) private var manager
	@Environment(ChatInputBarManager.self) private var inputManager
	@Environment(\.sendChatRoomAction) private var msgRoomAction
	@Environment(\.focusState) private var focusState
	@Environment(\.screenSize) private var screenSize

	var body: some View {
		HStack(alignment: .bottom, spacing: 8) {
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
			ChatTextField(
				text: .init(get: { inputManager.text }, set: { inputManager.text = $0 })
			) { _ in
			}
			.scrollDisabled(true)
			.layoutPriority(5)
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
