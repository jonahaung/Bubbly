//  PaginatedDatasource.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI

// © 2026 Aung Ko Min
import Core
import Database
import Services
import SwiftData
import Foundation

actor PaginatedDatasource {
    init(pageSize: Int) { self.pageSize = pageSize }
    func reset(conID: String) async throws -> [Message] {
        try await MsgRepo.msgs(conID: conID, limit: pageSize )
    }

    func previous(before date: Date, conID: String ) async throws -> [Message] {
        var descriptor = FetchDescriptor<PMsg>(
            predicate: PMsgPredicates.msgs(conID: conID, date: date, comparison: .lessThan),
            sortBy: [.init(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = pageSize
        let snapshots = try await Store.shared.msgStore?.fetch(descriptor) ?? []
        return Array(snapshots.reversed())
    }

    func msg(from date: Date, conID: String ) async throws -> [Message] {
        var descriptor = FetchDescriptor<PMsg>(
            predicate: PMsgPredicates.msgs(
                conID: conID, date: date, comparison: .lessThanOrEqual
            ),
            sortBy: [.init(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = pageSize
        let snapshots = try await Store.shared.msgStore?.fetch(descriptor) ?? []
        return Array(snapshots.reversed())
    }

    func more(after date: Date, conID: String ) async throws -> [Message] {
        var descriptor = FetchDescriptor<PMsg>(
            predicate: PMsgPredicates.msgs(conID: conID, date: date, comparison: .greaterThan ),
            sortBy: [.init(\.date, order: .forward)]
        )
        descriptor.fetchLimit = pageSize
        return try await Store.shared.msgStore?.fetch(descriptor) ?? []
    }

    private let pageSize: Int
}
