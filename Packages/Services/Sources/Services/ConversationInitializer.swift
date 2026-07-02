// © 2026 Aung Ko Min

import Core
import Database
import SwiftUI
import XUI

public enum ConversationInitializer {}
public extension ConversationInitializer {
    @concurrent
    static func route(msgID: String) async throws {
        guard let msg = try await Store.shared.msgStore?.fetch(uid: msgID) else {
            throw fatalError()
        }
        let conversation = try await ConversationRepo.getOrCreate(for: msg.conID, refetch: false)
        let prefetchedData = try await createPrefetchedObject(
            conversation: conversation,
            targetedMsg: msg,
        )
        await Router.shared.pushToNav(NavPath.conversation(prefetchedData))
    }

    @concurrent
    static func start(msgID: String) async throws {
        try await route(msgID: msgID)
    }
}
public extension ConversationInitializer {
    @concurrent
    static func start(conID: String, refetch: Bool) async throws {
        let conversation = try await ConversationRepo.getOrCreate(
            for: conID,
            refetch: refetch,
        )
        let prefetchedData = try await createPrefetchedObject(
            conversation: conversation,
        )
        await Router.shared.pushToNav(NavPath.conversation(prefetchedData))
    }
}
public extension ConversationInitializer {
    static func createPrefetchedObject(conversation: Conversation, targetedMsg: Message? = nil) async throws
        -> ConversationInitializedData
    {
        let conID = conversation.uid
        let msgsCount = try await MsgRepo.totalMsgsCount(
            conID: conID,
        )
        let pageSize = Settings.Pagination.pageSize
        
        var properties = try await ConversationPropertiesRepo.getOrCreate(
            for: conID,
            refetch: false,
        )
        let msgs: [Message]
        if let targetedMsg {
            msgs = try await MsgRepo.messages(conID: conID, to: targetedMsg.date, limit: pageSize)
            properties.lastPage = nil
        } else {
            if let lastPage = properties.lastPage, await lastPage.isPotrait == UIApplication.shared.screenSize().isPortrait, let top = try await Store.shared.msgStore?.fetch(uid: lastPage.topMsgID), let bottom = try await Store.shared.msgStore?.fetch(uid: lastPage.bottomMsgID) {
                msgs = try await MsgRepo.messages(conID: conID, from: top.date, to: bottom.date)
            } else {
                msgs = try await MsgRepo.msgs(
                    conID: conID,
                    limit: pageSize,
                )
            }
        }
        
        let firstMsg = try await MsgRepo.firstMsg(conID: conID)
        let lastMsg = try await MsgRepo.lastMsg(conID: conID)
        
        let pagination = PaginationState(
            conID: conversation.uid,
            pageSize: pageSize,
            lastMsgID: lastMsg?.uid,
            firstMsgID: firstMsg?.uid,
            totalMsgsCount: msgsCount
        )
        let lineSpacing = Settings.Layout.chatMsgSpacing.cgFloat
        let members = try await ContactRepo.getOrCreate(for: conversation.members, refatch: false)
        
        return ConversationInitializedData(
            conversation: conversation,
            properties: properties,
            msgs: msgs,
            pagination: pagination,
            members: .init(members: members.compactMap{ $0 }),
        )
    }
}
