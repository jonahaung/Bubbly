//  MsgRepo.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftData
import Foundation

public enum MsgRepo {

    public struct PaginationSnapshot: Sendable, Equatable {
        public let firstMsgID: String?
        public let lastMsgID: String?
        public let totalMsgsCount: Int
    }

    public enum MsgRepoError: Error {
        case noCurrentUserID
        case unknownError
        case storeError
    }

    private static func withMsgStore<T>(_ block: (StoreModelActor<PMsg>) async throws -> T) async throws -> T {
        guard let store = await Store.shared.msgStore else {
            throw MsgRepoError.storeError
        }
        return try await block(store)
    }

    fileprivate static func descriptor(
        for conID: String,
        order: SortOrder,
        limit: Int? = nil,
        offset: Int? = nil
    ) -> FetchDescriptor<PMsg> {
        var descriptor = FetchDescriptor<PMsg>(predicate: PMsgPredicates.conID(conID))
        descriptor.sortBy = [.init(\.date, order: order)]
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        return descriptor
    }

    public static func msgs(conID: String, offset: Int? = nil, limit: Int? = nil) async throws
    -> [Message] {
        let descriptor = descriptor(for: conID, order: .reverse, limit: limit, offset: offset)
        return try await withMsgStore { try await $0.fetch(descriptor).reversed() }
    }

    public static func deleteMessages(conID: String) async throws {
        try await withMsgStore { try await $0.delete(where: PMsgPredicates.conID(conID)) }
    }

    public static func lastMsg(conID: String) async throws -> Message? {
        try await withMsgStore { try await $0.fetch(descriptor(for: conID, order: .reverse, limit: 1)).first }
    }

    public static func firstMsg(conID: String) async throws -> Message? {
        try await withMsgStore { try await $0.fetch(descriptor(for: conID, order: .forward, limit: 1)).first }
    }

    public static func totalMsgsCount(conID: String) async throws -> Int {
        try await withMsgStore { try await $0.fetchCount(FetchDescriptor(predicate: PMsgPredicates.conID(conID))) }
    }

    public static func paginationSnapshot(conID: String) async throws -> PaginationSnapshot {
        try await withMsgStore {
            try await $0.paginationSnapshot(conID: conID)
        }
    }
    
    public static func messages(conID: String, from: Date, to: Date) async throws -> [Message] {
        var descriptor = FetchDescriptor<PMsg>(
            predicate: #Predicate {
                $0.conID == conID && $0.date >= from && $0.date <= to
            },
            sortBy: [.init(\.date, order: .forward)]
        )
        descriptor.sortBy = [.init(\.date, order: .forward)]
        return try await withMsgStore {
            try await $0.fetch(descriptor)
        }
    }
    public static func messages(conID: String, to: Date, limit: Int) async throws -> [Message] {
        var descriptor = FetchDescriptor<PMsg>(
            predicate: #Predicate {
                $0.conID == conID && $0.date <= to
            },
            sortBy: [.init(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try await withMsgStore {
            try await $0.fetch(descriptor).reversed()
        }
    }
}

private extension StoreModelActor where T == PMsg {
    func paginationSnapshot(conID: String) throws -> MsgRepo.PaginationSnapshot {
        let first = try fetch(MsgRepo.descriptor(for: conID, order: .forward, limit: 1)).first
        let last = try fetch(MsgRepo.descriptor(for: conID, order: .reverse, limit: 1)).first
        let count = try fetchCount(FetchDescriptor(predicate: PMsgPredicates.conID(conID)))

        return .init(
            firstMsgID: first?.uid,
            lastMsgID: last?.uid,
            totalMsgsCount: count
        )
    }
}

public extension MsgRepo {
    static func incomingUnreadMsgsCount(conID: String) async throws -> Int {
        let currentUserID = try CurrentUserID.get()
        return try await withMsgStore {
            try await $0.fetchCount(
                FetchDescriptor(
                    predicate: PMsgPredicates
                        .deliveryStatus(conID: conID, currentUserID: currentUserID, recipient: .incoming, deliveryStatus: .delivered, comparison: .lessThanOrEqual)
                )
            )
        }
    }

    static func incomingUnreadMsgs(conID: String) async throws -> [Message] {
        let currentUserID = try CurrentUserID.get()
        var descriptor = FetchDescriptor(
            predicate: PMsgPredicates
                .deliveryStatus(
                    conID: conID,
                    currentUserID: currentUserID,
                    recipient: .incoming,
                    deliveryStatus: .delivered,
                    comparison: .lessThanOrEqual
                )
        )
        descriptor.sortBy = [.init(\.date, order: .forward)]
        return try await withMsgStore {
            try await $0.fetch(descriptor)
        }
    }

    static func messages(
        for conID: String,
        recipient: MsgRecipient,
        deliveryStatus: DeliveryStatus,
        comparison: PredicateExpressions.ComparisonOperator?
    ) async throws -> [Message] {

        let currentUserID = try CurrentUserID.get()

        let predicate: Predicate<PMsg> = if let comparison {
            PMsgPredicates.deliveryStatus(
                conID: conID,
                currentUserID: currentUserID,
                recipient: recipient,
                deliveryStatus: deliveryStatus,
                comparison: comparison
            )
        } else {
            PMsgPredicates.deliveryStatusEqual(
                conID: conID,
                currentUserID: currentUserID,
                recipient: recipient,
                incomingStatus: deliveryStatus
            )
        }

        return try await withMsgStore {
            var descriptor = FetchDescriptor<PMsg>(predicate: predicate)
            descriptor.sortBy = [.init(\.date, order: .forward)]
            return try await $0.fetch(descriptor)
        }
    }

    static func outgoingUnreadMsgs(conID: String)
        async throws -> [Message] {
        let currentUserID = try CurrentUserID.get()
        return try await withMsgStore(
            { store in
                var descriptor = FetchDescriptor<PMsg>(
                    predicate: PMsgPredicates
                        .deliveryStatus(
                            conID: conID,
                            currentUserID: currentUserID,
                            recipient: .outgoing,
                            deliveryStatus: .delivered,
                            comparison: .lessThanOrEqual
                        )
                )
                descriptor.sortBy = [.init(\.date, order: .forward)]
                return try await store.fetch(descriptor)
            }
        )
    }
}
