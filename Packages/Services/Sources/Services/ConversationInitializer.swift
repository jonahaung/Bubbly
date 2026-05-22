// © 2026 Aung Ko Min

import Core
import Database
import SwiftUI
import XUI

public enum ConversationInitializer {

    public struct PrefetchedData: Hashable, Sendable {
        public let conversation: Conversation
        public let properties: ConversationProperties
        public let msgs: [Message]
        public let pagination: PaginationState
        public let members: Members

        public init(
            conversation: Conversation,
            properties: ConversationProperties,
            msgs: [Message],
            pagination: PaginationState,
            members: Members
        ) {
            self.conversation = conversation
            self.properties = properties
            self.msgs = msgs
            self.pagination = pagination
            self.members = members
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
        
        let properties = try await ConversationPropertiesRepo.getOrCreate(
            for: conID,
            refetch: false,
        )
        let msgs: [Message]
        if let lastPage = properties.lastPage, await lastPage.isPotrait == UIApplication.shared.screenSize().isPortrait, let top = try await Store.shared.msgStore?.fetch(uid: lastPage.topMsgID), let bottom = try await Store.shared.msgStore?.fetch(uid: lastPage.bottomMsgID) {
            msgs = try await MsgRepo.messages(conID: conID, from: top.date, to: bottom.date)
        } else {
            msgs = try await MsgRepo.msgs(
                conID: conID,
                limit: pageSize,
            )
        }
        let firstMsg = try await MsgRepo.firstMsg(conID: conID)
        let lastMsg = try await MsgRepo.lastMsg(conID: conID)
        
        let lineSpacing = Settings.Layout.chatMsgSpacing.cgFloat
        let members = try await ContactRepo.getOrCreate(for: conversation.members, refatch: false)
        
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
            ), members: .init(members: members.compactMap{ $0 }),
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
    static func start(conversation: Conversation, router: Router) async throws {
        let prefetchedData = try await createPrefetchedObject(
            conversation: conversation,
        )
        await router.pushToNav(NavPath.conversation(prefetchedData))
    }
}
