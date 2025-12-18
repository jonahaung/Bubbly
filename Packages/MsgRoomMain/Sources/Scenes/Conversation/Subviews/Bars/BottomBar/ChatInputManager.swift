//
//  ChatInputBarManager.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 26/6/24.
//

import Core
import Database
import MediaPicker
import PhotosUI
import Services
import SwiftUI
import XUI

@MainActor
@Observable
final class ChatInputManager {

	@ObservationIgnored var inputText = InputText()
	@ObservationIgnored var imagePicker = ImagePickerViewModel()
	let msgCreater: MsgCreator
	let languageManaager: LanguageModelService = .init(role: .friend)

	init() {
		msgCreater = .init(currentUserId: currentUserId ?? "")
	}

	var hasContent: Bool {
		inputText.hasText || imagePicker.selections.isEmpty == false
	}

	deinit {
		Log("")
	}

	func send(conversation: Conversation) {
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

	func sendToAI(conversation: Conversation) {
		guard inputText.hasText else { return }
		let string = inputText.text.string.trimmed
		inputText.clear()
		Task {
			do {
				var msg = try await msgCreater.create(text: string, in: conversation)
				msg.outgoingStatus = [AI.contact.uid: MsgOutgoingStatus.sent]
				try await Socket.shared.send(.newMsg(rMsg: .init(msg)), conversation: conversation)
				let response = try await languageManaager.respond(to: string).trimmed.replace("\n\n", with: "\n ")
				let replyMsg = RMsg(
					uid: UUID().uuidString,
					conID: conversation.uid,
					msgKind: response.isMarkdown ? .markdown : .text,
					senderID: AI.contact.uid,
					date: ServerTime.now.value,
					text: response,
					incomingStatus: .read,
					outgoingStatus: .init(),
					attachment: nil
				)
				try await Socket.shared.send(.newMsg(rMsg: replyMsg), conversation: conversation)
			} catch {
				Log(error)
			}
		}
	}

	func sendImages(conversation: Conversation) {
		// Prefer inheriting context rather than detached to avoid racing shared singletons.
		Task(priority: .background) { [self] in
			do {
				try await withThrowingTaskGroup(of: Void.self) { group in
					for (id, image) in imagePicker.processedPhotos {
						group.addTask { [self] in
							await imagePicker.remove(for: id)
							let msg = try await msgCreater.create(from: image, in: conversation)
							try await Task.sleep(seconds: 2)
							await Socket.shared.notifyMessage(.newMsg(rMsg: .init(msg)))
						}
					}
					try await group.waitForAll()
				}
			} catch {
				Log(error)
			}
		}
	}

	func sendText(conversation: Conversation) {
		guard inputText.hasText else {
			inputText.set(Lorem.random)
			return
		}
		let string = inputText.text.trimmed
		let link = inputText.linkPreview

		inputText.clear()

		Task {
			do {
				let msg = try await msgCreater.create(
					text: string,
					link: link?.finalUrl, in: conversation
				)
				try await Socket.shared.send(.newMsg(rMsg: .init(msg)), conversation: conversation)
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
			#"\[.+\]\(.+\)"#,  // [text](link)
			#"^#{1,6}\s"#,  // # Heading
			#"^\s*[-*+]\s"#,  // - List item
			#"!\[.*\]\(.+\)"#,  // ![alt](img)
			#"`[^`]+`"#  // `code`
		]
		return markdownPatterns.contains { self.range(of: $0, options: .regularExpression) != nil }
	}
}
