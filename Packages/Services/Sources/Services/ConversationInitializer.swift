// © 2026 Aung Ko Min

import Core
import Database
import SwiftUI
import XUI

// MARK: - ConversationInitializer

public enum ConversationInitializer {
    public struct PaginationState: Hashable, Sendable {
        public let conID: String
        public let pageSize: Int
        public let lineSpacing: CGFloat
        public let lastMsgID: String?
        public let firstMsgID: String?
        public var totalMsgsCount: Int
        public let canPaginate: Bool
    }

    public struct PrefetchedData: Hashable, Sendable {
        public let conversation: Conversation
        public let properties: ConversationProperties
        public let msgs: [Message]
        public let configuration: PaginationState

        public init(
            conversation: Conversation,
            properties: ConversationProperties,
            msgs: [Message],
            configuration: PaginationState,
        ) {
            self.conversation = conversation
            self.properties = properties
            self.msgs = msgs
            self.configuration = configuration
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
            limit: pageSize * 2,
        )
        let firstMsg = try await MsgRepo.firstMsg(conID: conID)
        let lastMsg = msgs.last
        let properties = try await ConversationPropertiesRepo.getOrCreate(
            for: conID,
            refetch: false,
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
                totalMsgsCount: msgsCount,
                canPaginate: msgsCount > msgs.count,
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
