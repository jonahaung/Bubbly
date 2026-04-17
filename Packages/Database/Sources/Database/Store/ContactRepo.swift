// © 2026 Aung Ko Min

import Core
import Foundation
import SwiftData
import XUI

public enum ContactRepo {
    enum XError: Error {
        case noCurrentUserID
        case savingFailed
        case noContactFound
    }

    @discardableResult
    public static func getOrCreate(uid: String, refetch: Bool) async throws -> Contact {
        let localValue = try await Store.shared.contactStore?.fetch(uid: uid)
        if let localValue, !refetch {
            return localValue
        }
        let serverValue: Contact? = try? await FirestoreRepo.getModel(
            for: uid,
            collection: .users,
            field: .uid,
        )
        guard let serverValue else {
            if let localValue {
                return localValue
            } else {
                throw XError.noContactFound
            }
        }

        try await Store.shared.contactStore?.insert(serverValue)
        return serverValue
    }

    @discardableResult
    public static func getOrCreate(for uids: [String], refatch: Bool) async throws -> [Contact] {
        try await AsyncOrderedStream.mapOrdered(inputs: uids) { uid in
            try await ContactRepo.getOrCreate(
                uid: uid,
                refetch: refatch,
            )
        }
    }

    public static func search(named name: String) async throws -> Contact? {
        let targetName = name
        var descriptor = FetchDescriptor<PContact>(
            predicate: #Predicate {
                $0.name == targetName
            },
        )
        descriptor.fetchLimit = 1
        return try await Store.shared.contactStore?.fetch(descriptor).first
    }

    public static func searchGroup(named name: String) async throws -> Group? {
        let targetName = name
        var descriptor = FetchDescriptor<PGroup>(
            predicate: #Predicate {
                $0.name == targetName
            },
        )
        descriptor.fetchLimit = 1
        return try await Store.shared.groupStore?.fetch(descriptor).first
    }
}
