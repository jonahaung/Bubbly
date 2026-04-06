//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Services
import SwiftData
import XUI

@MainActor
struct InboxRepositoryImpl: InboxRepository {
    private let manager: InboxManager

    init(manager: InboxManager) {
        self.manager = manager
    }

    func observe(currentUser: CurrentUserModel) async throws -> InboxSnapshot {
        manager.setCurrentUser(currentUser)
        let items = try await loadInboxItems(currentUser: currentUser)
        manager.setItems(items)
        return snapshot()
    }

    func refresh() async throws -> InboxSnapshot {
        let items = try await loadInboxItems(currentUser: manager.currentUser)
        manager.setItems(items)
        return snapshot()
    }

    func latestSnapshot() async -> InboxSnapshot {
        snapshot()
    }

    private func loadInboxItems(currentUser: CurrentUserModel) async throws -> [InboxItem] {
        let conversations = try await fetchContactConversations()
        return try await fetchInboxItems(conversations, currentUser: currentUser)
    }

    private func fetchInboxItems(
        _ conversations: [Conversation],
        currentUser: CurrentUserModel
    ) async throws -> [InboxItem] {
        let items: [InboxItem?] = try await AsyncOrderedStream
            .mapOrdered(inputs: conversations) { conversation in
				if let msg = try await MsgRepo.lastMsg(conID: conversation.uid) {
                    let sender: any ContactRepresentableSendable =
                        if msg.receiptType == .incoming {
                            try await ContactRepo.getOrCreate(uid: msg.senderID, refetch: false)
                        } else {
                            currentUser
                        }
					let unreadMsgsCount = try await MsgRepo.incomingUnreadMsgsCount(
                        conID: conversation.uid,
                        currentUserID: currentUser.uid
                    )
					print(unreadMsgsCount)
                    return InboxItem(
                        conversation: conversation,
                        msg: msg,
                        sender: sender,
                        unreadMsgsCount: unreadMsgsCount
                    )
                }
                return nil
            }
        return items.compactMap(\.self).sorted(by: { $0.msg.date > $1.msg.date })
    }

    private func fetchContactConversations() async throws -> [Conversation] {
        var descriptor = FetchDescriptor<PConversationProperties>()
        descriptor.sortBy = [.init(\.uid, order: .forward)]
        let properties = try await Store.shared.conversationPropertiesStore?.fetch(descriptor)

        return try await withThrowingTaskGroup(of: Conversation.self) { group in
            properties?.forEach { property in
                let conID = property.uid
                group.addTask {
                    try await ConversationRepo.getOrCreate(for: conID, refetch: false)
                }
            }
            var items = [Conversation]()
            for try await item in group {
                items.append(item)
            }
            return items
        }
    }

    private func snapshot() -> InboxSnapshot {
        InboxSnapshot(items: manager.items)
    }
}
