//
//  ConversationInitializer.swift
//  Services
//
//  Created by Aung Ko Min on 14/7/25.
//

import SwiftUI
import Database
import Core

public struct ConversationInitializer {
	public struct Configuration: Sendable {
		public let conID: String
		public let pageSize: Int
		public let lineSpacing: CGFloat
		public let lastMsgID: String?
		public let firstMsgID: String?
		public let totalMsgsCount: Int
		public let canPaginate: Bool
		public var maxNumberOfMsgsToDisplay: Int { pageSize * 2 }
		public let contentInsets = EdgeInsets(
			top: ChatLayoutConstants.topBarHeight,
			leading: 4,
			bottom: ChatLayoutConstants.bottomBarHeight,
			trailing: 4
		)
	}
	public struct PrefetchedData: Sendable {
		public let conversation: ConversationSnapshot
		public let msgs: [MsgSnapshot]
		public let configuration: Configuration

		public init(
			conversation: ConversationSnapshot,
			msgs: [MsgSnapshot],
			configuration: Configuration
		) {
			self.conversation = conversation
			self.msgs = msgs
			self.configuration = configuration
		}
	}
}

public extension ConversationInitializer {

	static func createPrefetchedObject(conversation: ConversationSnapshot) async throws -> PrefetchedData {
		let conID = conversation.uid
		let msgsCount = try await ConversationRepo.totalMsgsCount(
			conID: conID
		)
		let pageSize = Settings.Pagination.pageSize
		let msgs = try await ConversationRepo.fetchMessages(
			conID: conID,
			limit: pageSize
		)
		let firstMsg = try await ConversationRepo.firstMsg(conID: conID)
		let conversationKit = PrefetchedData(
			conversation: conversation,
			msgs: msgs,
			configuration: .init(
				conID: conversation.uid,
				pageSize: pageSize,
				lineSpacing: Settings.Layout.chatMsgSpacing.cgFloat,
				lastMsgID: msgs.last?.uid,
				firstMsgID: firstMsg?.uid,
				totalMsgsCount: msgsCount,
				canPaginate: msgsCount > msgs.count
			)
		)
		return conversationKit
	}
}
public extension ConversationInitializer {
	static func start(contact: ContactSnapshot, refetch: Bool) {
		if let currentUserID = GroupAppStorage.shared.string(
			for: .auth(.currentUserID)
		) {
			let conID = ConversationRepo.createConversationID(
				for: currentUserID,
				two: contact.uid
			)
			start(conID: conID, refetch: refetch)
		}
	}

	static func start(conID: String, refetch: Bool, delay: Double = 0) {
		Task.detached(priority: .background) {
			do {
				let conversation = try await ConversationRepo.getOrCreate(
					for: conID, refetch: refetch
				)
				if delay > 0 {
					try await Task.sleep(seconds: delay)
				}
				try await initializeAndPush(conversation: conversation)
			} catch {
				debugPrint(error)
			}
		}
	}

	static func start(conversation: ConversationSnapshot) {
		Task.detached {
			do {
				try await initializeAndPush(conversation: conversation)
			} catch {
				debugPrint(error)
			}
		}
	}
	static func initializeAndPush(conversation: ConversationSnapshot) async throws {
		let conversationKit = try await createPrefetchedObject(
			conversation: conversation
		)
		await MainActor.run {
			Router.shared.push(.conversation(conversationKit))
		}
	}
}
