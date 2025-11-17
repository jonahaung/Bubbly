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
final class ChatInputBarManager {
    var text: String = ""
    var imagePicker = ImagePickerViewModel()
    let msgCreater: MsgCreator
    var languageManaager: LanguageModelService = .init(role: .friend)

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

    func sendToAI(conversation: any ConversationRepresentable) {
        guard !text.isWhitespace else { return }
        let string = text.trimmed
        text = ""
        Task {
            do {
                var msg = await msgCreater.create(text: string, in: conversation)
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

    func sendImages(conversation: any ConversationRepresentable) {
        Task.detached(priority: .background) { [self] in
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for (id, image) in await imagePicker.processedPhotos {
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
            #"(^|\s)[*_]{1,2}.+[*_]{1,2}($|\s)"#, // *italic* or **bold**
            #"\[.+\]\(.+\)"#, // [text](link)
            #"^#{1,6}\s"#, // # Heading
            #"^\s*[-*+]\s"#, // - List item
            #"!\[.*\]\(.+\)"#, // ![alt](img)
            #"`[^`]+`"#, // `code`
        ]
        return markdownPatterns.contains { self.range(of: $0, options: .regularExpression) != nil }
    }
}
