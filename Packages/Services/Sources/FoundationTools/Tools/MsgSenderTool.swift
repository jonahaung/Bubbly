
//  MsgSenderTool.swift
//  Services
//
//  Created by Aung Ko Min on 6/1/26.
//

import Foundation
import FoundationModels
import Database
import SwiftData
import Core
import XUI

public struct MsgSenderTool: Tool {


	public let name = "sendMsg"
	public let description = "Search conversation, and send a message in the app."

	public init() {}

	@Generable
	public struct Arguments {
		@Guide(description: "The action to perform: 'send'")
		public var action: String
		@Guide(description: "Contact name to search for the contact and send a message (for search action)")
		public var name: String?
		@Guide(description: "The text to send as a message to perform: 'send'")
		public var text: String

		public init(
			action: String,
			name: String? = nil,
			text: String
		) {
			self.action = action
			self.name = name
			self.text = text
		}
	}

	public func call(arguments: Arguments) async throws -> GeneratedContent {

		guard let name = arguments.name, !name.isEmpty else {
			return createErrorOutput(error: LocalError.invalidArguments)
		}
		guard let currentUserId = GroupStorage.shared.string(for: .auth(.currentUserID)) else {
			return createErrorOutput(error: LocalError.accessDenied)
		}
		guard let conversation = try await ConversationRepo.search(form: name, currentUserId: currentUserId) else {
			return createErrorOutput(error: LocalError.conversationNotFoune)
		}

		let msg = try await MsgCreator(currentUserId: currentUserId).message(
			text: arguments.text,
			attachments: [],
			in: conversation
		)
		try await Socket.shared.send(.newMsg(rMsg: .init(msg)), conversation: conversation)
		return GeneratedContent(properties: [
			"name": arguments.name,
			"text": arguments.text
		])
	}

	private func createErrorOutput(error: Error) -> GeneratedContent {
		GeneratedContent(properties: [
			"status": "error",
			"error": error.localizedDescription,
			"message": "Failed to perform contact operation"
		])
	}


	enum LocalError: Error, LocalizedError, CaseNameReflectable {
		case accessDenied, invalidArguments
		case conversationNotFoune

		var errorDescription: String? {
			caseName
		}
	}
}

@Generable
public struct MsgSenderToolOutput {
	@Guide(description: "The action to perform: 'send'")
	public var action: String
	@Guide(description: "Contact name to search for the contact and send a message (for search action)")
	public var name: String?
	@Guide(description: "The text to send as a message to perform: 'send'")
	public var text: String

	public init(
		action: String,
		name: String? = nil,
		text: String
	) {
		self.action = action
		self.name = name
		self.text = text
	}
	}
