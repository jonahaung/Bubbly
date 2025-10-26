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
final class ChatInputBarManager {

	var text: String = ""
	var imagePicker = ImagePickerViewModel()
	let msgCreater: MsgCreator

	init() throws {
		msgCreater = try .init(currentUserId: currentUserId)
	}

	var hasContent: Bool {
		text.isWhitespace == false || imagePicker.selections.isEmpty == false
	}

	func send(conversation: any ConversationRepresentable) {
		if imagePicker.processedPhotos.isEmpty == false {
			sendImages(conversation: conversation)
		} else {
			sendText(conversation: conversation)
		}
	}

	func sendImages(conversation: any ConversationRepresentable) {
		Task.detached(priority: .background) { [self] in
			do {
				try await withThrowingTaskGroup(of: Void.self) { group in
					for (id, image) in await imagePicker.processedPhotos {
						group.addTask { [self] in
							await imagePicker.remove(for: id)
							let msg = try await msgCreater.create(from: image, in: conversation)
							try await Task.sleep(seconds: 2)

							// Notify UI
							await Socket.shared.notifyMessage(.newMsg(rMsg: .init(msg: msg)))
						}
					}

					// Wait for all image tasks to finish
					try await group.waitForAll()
				}
			} catch {
				Log(error)
			}
		}
	}
	func sendText(conversation: any ConversationRepresentable) {
		let string = text
		text.removeAll()
		if string.isWhitespace {
			text = Lorem.random
			return
		}
		Task {
			do {
				if let url = URL(string: string), url.host() != nil {
					let msg = try await self.msgCreater.create(from: url, in: conversation)
					await Socket.shared.send(.newMsg(rMsg: .init(msg: msg)), conversation: conversation)
				} else {
					let msg = await msgCreater.create(text: string, in: conversation)
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
