//
//  SendButton.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/1/26.
//

import SwiftUI
import Database
import Services
import SFSafeSymbols
import XUI

extension ComposeBar {
	struct SendButton: View {

		@Environment(ChatComposer.self) private var composer: ChatComposer
		@Environment(\.conversation) private var conversation
		@Environment(\.sendChatRoomAction) private var msgRoomAction
		@Environment(\.sharedNamespace) private var namespace
		@Environment(\.sharedFocusState) private var sharedFocus
		@Environment(ChatViewManager.self) private var chatViewManager

		enum ButtonType: Hashable {
			case send, emoji, writingTools, imageGenerator
			var systemImageName: String {
				switch self {
				case .writingTools:
					return "apple.intelligence"
				case .emoji:
					return "heart.circle.fill"
				case .send:
					return "arrowshape.up.circle.fill"
				case .imageGenerator:
					return "checkmark.circle.fill"
				}
			}
		}

		private var buttonType: ButtonType {
			if composer.hasContent {
				if composer.composeType == .machineImag {
					return .imageGenerator
				} else {
					return .send
				}
			} else if chatViewManager.messageItems.array.last?.msg.isSender == false {
				return .writingTools
			} else {
				return .emoji
			}
		}
		var body: some View {
			AsyncButton(
				options: [.disallowParallelOperations, .showAlertOnError, .showProgressViewOnLoading]
			) {
				try await action(buttonType: buttonType)
			} label: {
				Image(systemName: buttonType.systemImageName)
					.symbolColorRenderingMode(.gradient)
					.symbolVariableValueMode(.draw)
					.resizable()
					.scaledToFit()
					.imageScale(.small)
			}
			.symbolRenderingMode(.multicolor)
			.contentTransition(.symbolEffect(.replace))
			.frame(width: 32, height: 32, alignment: .bottom)
			.animation(.spring, value: buttonType)
			.geometryGroup()
		}

		private func action(buttonType: ButtonType) async throws {
			switch buttonType {
			case .send:
				composer.send(conversation: conversation)
			case .emoji:
				composer.send(conversation: conversation)
			case .writingTools:
				if Platform.isSimulator {
					composer.send(conversation: conversation)
				} else {
					let mediaEngine = ChatEngine()
					guard mediaEngine.isAvailable else {
						throw NSError(domain: "com.example.ChatLayout", code: 0, userInfo: nil)
					}
					let lastIndex = chatViewManager.messageItems.array
						.lastIndex(where: { $0.layout.showTimeSeparator == true }) ?? 0
					let msgs = chatViewManager.messageItems.array.suffix(from: lastIndex).map(\.msg)
					let summery = try await mediaEngine.summarize(
						msgs: msgs,
						previousSummary: chatViewManager.presentation.summary
					)
					let response = try await mediaEngine.respondTo(
						msgs: msgs,
						summary: summery
					)
					Task { @MainActor in
						composer.inputText.text = response.content
					}
				}
			case .imageGenerator:
				try await composer.generateImage(prompt: composer.inputText.text)
				composer.composeType = .text
			}
		}
	}
}
