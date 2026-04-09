// © 2026 Aung Ko Min

import Core
import Foundation
import SwiftData
import XUI

// MARK: - MsgRepo

public enum MsgRepo {
    public enum XError: Error {
        case noCurrentUserID
        case unknownError
    }

    private static func withMsgStore<T>(
        _ block: (StoreModelActor<PMsg>) async throws -> T,
        defaultValue: T,
    ) async throws -> T {
        guard let store = await Store.shared.msgStore else {
            return defaultValue
        }

        return try await block(store)
    }

    static func descriptor(
        for conID: String,
        order: SortOrder,
        limit: Int? = nil,
        offset: Int? = nil,
    ) -> FetchDescriptor<PMsg> {
        var descriptor = FetchDescriptor<PMsg>(predicate: .conID(conID))
        descriptor.sortBy = [.init(\.date, order: order)]
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        return descriptor
    }

    public static func msgs(conID: String, offset: Int? = nil, limit: Int? = nil) async throws
        -> [Message]
    {
        try await withMsgStore(
            {
                try await $0.fetch(
                    descriptor(for: conID, order: .reverse, limit: limit, offset: offset),
                )
                .reversed()
            },
            defaultValue: [],
        )
    }

    public static func deleteMessages(conID: String) async throws {
        try await withMsgStore({ try await $0.delete(where: .conID(conID)) }, defaultValue: ())
    }

    public static func lastMsg(conID: String) async throws -> Message? {
        try await withMsgStore(
            { try await $0.fetch(descriptor(for: conID, order: .reverse, limit: 1)).first },
            defaultValue: nil,
        )
    }

    public static func firstMsg(conID: String) async throws -> Message? {
        try await withMsgStore(
            { try await $0.fetch(descriptor(for: conID, order: .forward, limit: 1)).first },
            defaultValue: nil,
        )
    }

    public static func totalMsgsCount(conID: String) async throws -> Int {
        try await withMsgStore(
            { try await $0.fetchCount(FetchDescriptor(predicate: .conID(conID))) },
            defaultValue: 0,
        )
    }
}

public extension MsgRepo {
    static func incomingUnreadMsgsCount(conID: String, currentUserID: String) async throws
        -> Int
    {
        try await withMsgStore(
            {
                try await $0.fetchCount(
                    FetchDescriptor(
                        predicate: Predicate<PMsg>
                            .deliveryStatusComparison(
                                conID: conID,
                                currentUserID: currentUserID,
                                recipient: .incoming,
                                deliveryStatus: .read,
                                comparison: .lessThan,
                            ),
                    ),
                )
            },
            defaultValue: 0,
        )
    }

    static func incomingUnreadMsgs(conID: String, limit: Int? = nil, currentUserID: String)
        async throws -> [Message]
    {
        try await withMsgStore(
            { store in
                var descriptor = FetchDescriptor<PMsg>(
                    predicate: Predicate<PMsg>
                        .deliveryStatusComparison(
                            conID: conID,
                            currentUserID: currentUserID,
                            recipient: .incoming,
                            deliveryStatus: .read,
                            comparison: .lessThan,
                        ),
                )
                descriptor.fetchLimit = limit
                descriptor.sortBy = [.init(\.date, order: .forward)]
                return try await store.fetch(descriptor)
            },
            defaultValue: [],
        )
    }

    static func outgoingUnreadMsgs(conID: String, currentUserID: String)
        async throws -> [Message]
    {
        try await withMsgStore(
            { store in
                var descriptor = FetchDescriptor<PMsg>(
                    predicate: Predicate<PMsg>
                        .deliveryStatusComparison(
                            conID: conID,
                            currentUserID: currentUserID,
                            recipient: .outgoing,
                            deliveryStatus: .delivered,
                            comparison: .greaterThanOrEqual,
                        ),
                )
                descriptor.sortBy = [.init(\.date, order: .forward)]
                return try await store.fetch(descriptor)
            },
            defaultValue: [],
        )
    }

    static func updateStatusForIncomingMsgs(for conID: String, currentUserID: String) async throws
        -> [Message]
    {
        let unreadMsgs = try await incomingUnreadMsgs(conID: conID, currentUserID: currentUserID)
        guard !unreadMsgs.isEmpty else {
            return []
        }

        let store = await Store.shared.msgStore
        return try await AsyncOrderedStream.mapOrdered(inputs: unreadMsgs) { msg in
            var updated = msg
            updated.deliveryStatus = .read
            try await store?.updateAndSave(uid: updated.uid) { $0.update(from: updated) }
            return updated
        }
    }

    @discardableResult
    static func updateSentMsgs(
        statusPayload: AnyMsgData.SeenStatusPayload,
        currentUserID: String,
    ) async throws
        -> [Message]
    {
        let deliveredMsgs = try await msgs(
            conID: statusPayload.conID,
            deliveryStatus: .delivered,
            recipient: .outgoing,
            currentUserID: currentUserID,
        )
        guard !deliveredMsgs.isEmpty else {
            return []
        }

        let store = await Store.shared.msgStore
        return try await AsyncOrderedStream.mapOrdered(inputs: deliveredMsgs) { msg in
            var updated = msg
            updated.deliveryStatus = .read
            try await store?.updateAndSave(uid: updated.uid) { $0.update(from: updated) }
            return updated
        }
    }

    static func msgs(
        conID: String,
        deliveryStatus: DeliveryStatus,
        recipient: MsgRecipient,
        currentUserID: String,
    )
        async throws -> [Message]
    {
        try await withMsgStore(
            { store in
                var descriptor = FetchDescriptor<PMsg>(
                    predicate: Predicate<PMsg>
                        .deliveryStatusEqual(
                            conID: conID,
                            currentUserID: currentUserID,
                            recipient: recipient,
                            deliveryStatus: deliveryStatus,
                        ),
                )
                descriptor.sortBy = [.init(\.date, order: .forward)]
                return try await store.fetch(descriptor)
            },
            defaultValue: [],
        )
    }
}
