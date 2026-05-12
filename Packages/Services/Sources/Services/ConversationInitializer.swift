// © 2026 Aung Ko Min

import Core
import Database
import SwiftUI
import XUI

public struct PaginationState: Hashable, Sendable {
    public let conID: String
    public let pageSize: Int
    public var lastMsgID: String?
    public let firstMsgID: String?
    public var totalMsgsCount: Int
}

public enum ConversationInitializer {

    public struct PrefetchedData: Hashable, Sendable {
        public let conversation: Conversation
        public let properties: ConversationProperties
        public let msgs: [Message]
        public let pagination: PaginationState

        public init(
            conversation: Conversation,
            properties: ConversationProperties,
            msgs: [Message],
            pagination: PaginationState,
        ) {
            self.conversation = conversation
            self.properties = properties
            self.msgs = msgs
            self.pagination = pagination
        }
    }
}

public extension ConversationInitializer {
    static func createPrefetchedObject(conversation: Conversation) async throws
        -> PrefetchedData
    {
        let conID = conversation.uid
        let msgsCount = try await MsgRepo.totalMsgsCount(
            conID: conID,
        )
        let pageSize = Settings.Pagination.pageSize
        let msgs = try await MsgRepo.msgs(
            conID: conID,
            limit: pageSize,
        )
        let firstMsg = try await MsgRepo.firstMsg(conID: conID)
        let lastMsg = try await MsgRepo.lastMsg(conID: conID)
        let properties = try await ConversationPropertiesRepo.getOrCreate(
            for: conID,
            refetch: false,
        )
        let lineSpacing = Settings.Layout.chatMsgSpacing.cgFloat
        return PrefetchedData(
            conversation: conversation,
            properties: properties,
            msgs: msgs,
            pagination: .init(
                conID: conversation.uid,
                pageSize: pageSize,
                lastMsgID: lastMsg?.uid,
                firstMsgID: firstMsg?.uid,
                totalMsgsCount: msgsCount
            ),
        )
    }
}

public extension ConversationInitializer {
    @concurrent
    static func start(conID: String, refetch: Bool, delay: Double = 0.0) async throws {
        let conversation = try await ConversationRepo.getOrCreate(
            for: conID,
            refetch: refetch,
        )
        if delay > 0 {
            try await Task.sleep(seconds: delay)
        }
        let prefetchedData = try await createPrefetchedObject(
            conversation: conversation,
        )
        await Router.shared.pushToNav(NavPath.conversation(prefetchedData))
    }

    @concurrent
    static func start(conversation: Conversation) async throws {
        let prefetchedData = try await createPrefetchedObject(
            conversation: conversation,
        )
        await Router.shared.pushToNav(NavPath.conversation(prefetchedData))
    }
}
