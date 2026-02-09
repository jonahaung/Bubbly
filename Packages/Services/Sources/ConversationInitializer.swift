//
//  ConversationInitializer.swift
//  Services
//
//  Created by Aung Ko Min on 14/7/25.
//

import Core
import Database
import SwiftUI
import XUI

public enum ConversationInitializer {
	public struct Configuration: Sendable {
		public let conID: String
		public let pageSize: Int
		public let lineSpacing: CGFloat
		public let lastMsgID: String?
		public let firstMsgID: String?
		public let totalMsgsCount: Int
		public let canPaginate: Bool
		public var maxNumberOfMsgsToDisplay: Int {
			pageSize * 2
		}

		public let contentInsets = EdgeInsets(
			top: ChatLayoutConstants.topBarHeight,
			leading: 8,
			bottom: 0,
			trailing: 8
		)
	}

	public struct PrefetchedData: Sendable {
		public let conversation: Conversation
		public let msgs: [Message]
		public let configuration: Configuration

		public init(conversation: Conversation,
		            msgs: [Message],
		            configuration: Configuration)
		{
			self.conversation = conversation
			self.msgs = msgs
			self.configuration = configuration
		}
	}
}

public extension ConversationInitializer {
	@concurrent
	static func createPrefetchedObject(conversation: Conversation) async throws -> PrefetchedData {
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
		return PrefetchedData(
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
	}
}

public extension ConversationInitializer {
	static func start(conID: String, refetch: Bool, delay: Double = 0) {
		Task.detached(priority: .background) {
			do {
				let conversation = try await ConversationRepo.getOrCreate(
					for: conID,
					refetch: refetch
				)
				if delay > 0 {
					try await Task.sleep(seconds: delay)
				}
				try await start(conversation: conversation)
			} catch {
				debugPrint(error)
			}
		}
	}

	static func start(conversation: Conversation) async throws {
		let prefetchedData = try await createPrefetchedObject(
			conversation: conversation
		)
		await Router.shared.pushToNav(NavPath.conversation(prefetchedData))
	}
}
