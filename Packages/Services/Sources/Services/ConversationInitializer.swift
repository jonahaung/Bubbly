//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import SwiftUI
import XUI

public enum ConversationInitializer {
	public struct Configuration: Hashable, Sendable {
		public let conID: String
		public let pageSize: Int
		public let lineSpacing: CGFloat
		public let lastMsgID: String?
		public let firstMsgID: String?
		public let firstUnreadMsgID: String?
		public var totalMsgsCount: Int
		public let canPaginate: Bool
	}

	public struct PrefetchedData: Hashable, Sendable {
		public let conversation: Conversation
		public let properties: ConversationProperties
		public let msgs: [Message]
		public let configuration: Configuration

		public init(
			conversation: Conversation,
			properties: ConversationProperties,
			msgs: [Message],
			configuration: Configuration
		) {
			self.conversation = conversation
			self.properties = properties
			self.msgs = msgs
			self.configuration = configuration
		}
	}
}

extension ConversationInitializer {

	public static func createPrefetchedObject(conversation: Conversation) async throws
		-> PrefetchedData
	{
		let conID = conversation.uid
		let msgsCount = try await MsgRepo.totalMsgsCount(
			conID: conID
		)
		let pageSize = Settings.Pagination.pageSize
		let msgs = try await MsgRepo.msgs(
			conID: conID,
			limit: pageSize
		)
		let firstMsg = try await MsgRepo.firstMsg(conID: conID)
		let lastMsg = msgs.last
		let properties = try await ConversationPropertiesRepo.getOrCreate(
			for: conID,
			refetch: false
		)
		let lineSpacing = Settings.Layout.chatMsgSpacing.cgFloat
		return PrefetchedData(
			conversation: conversation,
			properties: properties,
			msgs: msgs,
			configuration: .init(
				conID: conversation.uid,
				pageSize: pageSize,
				lineSpacing: lineSpacing,
				lastMsgID: lastMsg?.uid,
				firstMsgID: firstMsg?.uid,
 firstUnreadMsgID: msgs
					.first(
						where: { $0.receiptType == .incoming && $0.deliveryStatus != .read
						})?.uid,
				totalMsgsCount: msgsCount,
				canPaginate: msgsCount > msgs.count
			)
		)
	}
}

extension ConversationInitializer {
	@concurrent
	public static func start(conID: String, refetch: Bool, delay: Double = 0.2) async throws {
		let conversation = try await ConversationRepo.getOrCreate(
			for: conID,
			refetch: refetch
		)
		if delay > 0 {
			try await Task.sleep(seconds: delay)
		}
		let prefetchedData = try await createPrefetchedObject(
			conversation: conversation
		)
		await Router.shared.pushToNav(NavPath.conversation(prefetchedData))
	}
	@concurrent
	public static func start(conversation: Conversation) async throws {
		await Router.shared.setTabBar(visibility: .hidden)
		let prefetchedData = try await createPrefetchedObject(
			conversation: conversation
		)
		await Router.shared.pushToNav(NavPath.conversation(prefetchedData))
	}
}
