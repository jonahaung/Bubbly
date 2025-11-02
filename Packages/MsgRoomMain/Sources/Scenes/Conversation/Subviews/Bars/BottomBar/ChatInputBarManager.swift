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
	var languageManaager: LanguageManager = .init()

	func applyProgrammaticUpdate(_ newText: String) {
		guard newText != text else { return }
		text = newText
	}

	init() throws {
		msgCreater = try .init(currentUserId: currentUserId)
	}

	var hasContent: Bool {
		text.isWhitespace == false || imagePicker.selections.isEmpty == false
	}

	func send(conversation: any ConversationRepresentable) {
		switch conversation.kind {
		case .contact, .group:
			if imagePicker.processedPhotos.isEmpty == false {
				sendImages(conversation: conversation)
			}
			sendText(conversation: conversation)
		case .system:
			sendToAI(conversation: conversation)
		}
	}
	let openAIClient = OpenAIClient()
	func sendToAI(conversation: any ConversationRepresentable) {
		guard !text.isWhitespace else { return }
		let string = text.trimmed
		applyProgrammaticUpdate(String())

		Task {
			var msg = await msgCreater.create(text: string, in: conversation)
			msg.outgoingStatus = [AI.contact.uid: MsgOutgoingStatus.sent]
			do {
				try await Socket.shared.send(.newMsg(rMsg: .init(msg)), conversation: conversation)

				let chatCompletionResponse = try await openAIClient.request(.ask(input: string))
				_ =  try await AsyncOrderedStream.mapOrdered(inputs: chatCompletionResponse.choices) { choice in
					let replyText = choice.message.content.trimmed
					let role = choice.message.role
					let reply = RMsg.init(
						uid: UUID().uuidString,
						conID: conversation.uid,
						msgKind: replyText.isMarkdown ? .markdown : .text,
						senderID: AI.contact.uid,
						date: ServerTime.now.value,
						text: "\(role): \(replyText)",
						incomingStatus: .read,
						outgoingStatus: .init(),
						attachment: nil
					)
					try await Socket.shared.send(.newMsg(rMsg: reply), conversation: conversation)
				}

			} catch {
				Log(error)
			}
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
							await Socket.shared.notifyMessage(.newMsg(rMsg: .init(msg)))
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
		applyProgrammaticUpdate(String())
		if string.isWhitespace {
			applyProgrammaticUpdate(Lorem.random)
			return
		}
		Task {
			do {
				if let url = URL(string: string), url.host() != nil {
					let msg = try await self.msgCreater.create(from: url, in: conversation)
					try await Socket.shared.send(.newMsg(rMsg: .init(msg)), conversation: conversation)
				} else {
					let msg = await msgCreater.create(text: string, in: conversation)
					try await Socket.shared.send(.newMsg(rMsg: .init(msg)), conversation: conversation)
				}
			} catch {
				Log(error)
			}
		}
	}
}
extension String {
	var isMarkdown: Bool {
		let markdownPatterns = [
			#"(^|\s)[*_]{1,2}.+[*_]{1,2}($|\s)"#,  // *italic* or **bold**
			#"\[.+\]\(.+\)"#,                      // [text](link)
			#"^#{1,6}\s"#,                         // # Heading
			#"^\s*[-*+]\s"#,                       // - List item
			#"!\[.*\]\(.+\)"#,                     // ![alt](img)
			#"`[^`]+`"#                            // `code`
		]
		return markdownPatterns.contains { self.range(of: $0, options: .regularExpression) != nil }
	}
}
