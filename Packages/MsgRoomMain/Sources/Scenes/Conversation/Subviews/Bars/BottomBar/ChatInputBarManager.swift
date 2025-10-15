//
//  ChatInputBarViewModel.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 26/6/24.
//

import SwiftUI
import XUI
import PhotosUI
import MediaPicker
import Database
import Services

@MainActor
@Observable
final class ChatInputBarManager: Sendable {

	var text: String = ""
	var imagePicker = ImagePickerViewModel()


	init() {}

	var hasContent: Bool {
		text.isWhitespace == false || imagePicker.selections.isEmpty == false
	}

	func send(conversation: ConversationSnapshot) {
		if imagePicker.processedPhotos.isEmpty == false {
			sendImages(conversation: conversation)
		} else {
			sendText(conversation: conversation)
		}
	}

	func sendImages(conversation: ConversationSnapshot) {
		Task.detached(priority: .background) { [self] in
			let msgCreater = MsgCreater()
			do {
				try await imagePicker.processedPhotos.parallelEach { [self] id, image in
					await imagePicker.remove(for: id)
					let msg = try await msgCreater.create(image: image, conversation)
					try await Task.sleep(seconds: 2)
					await Socket.shared.notifyMessage(.newMsg(rMsg: .init(msg: msg)))
				}
			} catch {
				Log(error)
			}
		}
	}
	func sendText(conversation: ConversationSnapshot) {
		let string = text
		text.removeAll()
		if string.isWhitespace {
			text = Lorem.random
			return
		}
		Task.detached(priority: .background) {
			let msgCreater = MsgCreater()
			do {
				if let url = URL(string: string), url.host() != nil {
					let msg = try await msgCreater.create(url: url, conversation)
					await Socket.shared.send(.newMsg(rMsg: .init(msg: msg)), conversation: conversation)
				} else {
					let msg = try msgCreater.create(text: string, conversation)
					await Socket.shared.send(.newMsg(rMsg: .init(msg)), conversation: conversation)
				}
			} catch {
				Log(error)
			}
		}
	}

	func askAI(text: String) {
		//		let request = text.trimmed.contains("?") ? OpenAIPrompt.ask(input: text) : OpenAIPrompt.correct(
		//			input: text3
		//		)
		//		Task.detached(priority: .background) {
		//            if let result = try? await client.request(request) {
		//                UIPasteboard.general.string = result.trimmedText
		//				let msg = await MsgSnapshot.init(
		//					uid: UUID().uuidString,
		//					senderID: "OpenAIClient.chatContactId",
		//					conID: viewModel.conversation.uid,
		//					msgKind: .markdown,
		//					text: result.trimmedText,
		//					date: .now,
		//					deliveryStatus: .received
		//				)
		//				await viewModel.datasource(didInsert: msg)
		//				await msgRoomAction?(.newMsg(rMsg: .init(msg)))
		//            }
		//        }
	}
}
