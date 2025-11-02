//
//  ContactRepo.swift
//  Database
//
//  Created by Aung Ko Min on 28/10/25.
//

import Foundation
import XUI
import Core

public struct ContactRepo {
	enum XError: Error {
		case noCurrentUserID
		case savingFailed
		case noContactFound
	}
	@discardableResult
	public static func getOrCreate(for uid: String, refetch: Bool) async throws -> Contact {
		let localValue = try await Store.shared.contactStore.fetch(uid: uid)
		if let localValue, !refetch {
			return localValue
		}
		let serverValue: RContact? = try? await FirestoreRepo.getModel(for: uid, collection: .users, field: .uid)
		guard let serverValue else {
			if let localValue {
				return localValue
			} else {
				throw XError.noContactFound
			}
		}
		if let localValue {
			let newValue = localValue.merging(from: serverValue)
			try await Store.shared.contactStore.updateAndSave(uid: uid) { model in
				model.update(with: newValue)
			}
			return newValue
		} else {
			let newValue = Contact(serverValue)
			try await Store.shared.contactStore.insert(newValue)
			return newValue
		}
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
			memberIDs.forEach { uid in
				group.addTask {
					return try await ContactRepo.getOrCreate(
						for: uid,
						refetch: refatch
					)
				}
			}
			return try await group.map { $0 }.reduce(into: []) { $0.append($1) }
		}
	}
}
