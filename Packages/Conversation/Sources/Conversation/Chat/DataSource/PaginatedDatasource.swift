// © 2026 Aung Ko Min

import Core
import Database
import Foundation
import Services
import SwiftData
import XUI

actor PaginatedDatasource {
    // MARK: Lifecycle

    init(pageSize: Int) {
        self.pageSize = pageSize
    }

    // MARK: Internal

    func reset(conID: String) async throws -> [Message] {
        try await MsgRepo.msgs(
            conID: conID,
            limit: pageSize,
        )
    }

    func previous(
        before date: String,
        conID: String,
    ) async throws -> [Message] {
        var descriptor = FetchDescriptor<PMsg>(
            predicate: .msgs(conID: conID, date: date, comparison: .lessThan),
            sortBy: [.init(\.date, order: .reverse)],
        )
        descriptor.fetchLimit = pageSize
        let snapshots = try await Store.shared.msgStore?.fetch(descriptor) ?? []

        return Array(snapshots.reversed())
    }

    func msg(
        from date: String,
        conID: String,
    ) async throws -> [Message] {
        var descriptor = FetchDescriptor<PMsg>(
            predicate: .msgs(conID: conID, date: date, comparison: .lessThanOrEqual),
            sortBy: [.init(\.date, order: .reverse)],
        )
        descriptor.fetchLimit = pageSize
        let snapshots = try await Store.shared.msgStore?.fetch(descriptor) ?? []

        return Array(snapshots.reversed())
    }

    func more(
        after date: String,
        conID: String,
    ) async throws -> [Message] {
        var descriptor = FetchDescriptor<PMsg>(
            predicate: .msgs(conID: conID, date: date, comparison: .greaterThan),
            sortBy: [.init(\.date, order: .forward)],
        )
        descriptor.fetchLimit = pageSize
        return try await Store.shared.msgStore?.fetch(descriptor) ?? []
    }

    // MARK: Private

    private let pageSize: Int
}
