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
	public static func getOrCreate(for uid: String, refetch: Bool) async throws -> Contact {
		let localValue = try await Store.shared.contactStore?.fetch(uid: uid)
		if let localValue, !refetch {
			return localValue
		}
		let serverValue: Contact? = try? await FirestoreRepo.getModel(
			for: uid,
			collection: .users,
			field: .uid
		)
		guard let serverValue else {
			if let localValue {
				return localValue
			} else {
				throw XError.noContactFound
			}
		}
		if localValue != nil {
			try await Store.shared.contactStore?.updateAndSave(uid: uid) { model in
				model.merge(from: serverValue)
			}
		} else {
			try await Store.shared.contactStore?.insert(serverValue)
		}
		return serverValue
	}

	@discardableResult
	public static func getOrCreate(for uids: [String], refatch: Bool) async throws -> [Contact] {
		guard let currentUserId else {
			throw XError.noCurrentUserID
		}
		let memberIDs = uids.filter {
			!$0.isWhitespace && $0 != currentUserId
		}
		return try await withThrowingTaskGroup(of: Contact.self) { group -> [Contact] in
			for uid in memberIDs {
				group.addTask {
					try await ContactRepo.getOrCreate(
						for: uid,
						refetch: refatch
					)
				}
			}
			return try await group.map(\.self).reduce(into: []) { $0.append($1) }
		}
	}

	public static func search(named name: String) async throws -> Contact? {
		let targetName = name
		var descriptor = FetchDescriptor<PContact>(
			predicate: #Predicate {
				$0.name == targetName
			}
		)
		descriptor.fetchLimit = 1
		return try await Store.shared.contactStore?.fetch(descriptor).first
	}

	public static func searchGroup(named name: String) async throws -> Group? {
		let targetName = name
		var descriptor = FetchDescriptor<PGroup>(
			predicate: #Predicate {
				$0.name == targetName
			}
		)
		descriptor.fetchLimit = 1
		return try await Store.shared.groupStore?.fetch(descriptor).first
	}
}
