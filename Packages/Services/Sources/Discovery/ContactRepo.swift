//
//  ContactRepo.swift
//  Services
//
//  Created by Aung Ko Min on 16/5/25.
//

import Foundation
import Database
import FirebaseFirestore
import XUI
import Core

public struct ContactRepo {
	enum XError: Error {
		case noCurrentUserID
		case savingFailed
		case noContactFound
	}

	public static func getOrCreate(for uid: String, refatch: Bool) async throws -> Contact {
		let localValue = try await Store.shared.contactStore.fetch(uid: uid)

		if let localValue, !refatch {
			return localValue
		}
		let serverValue = try await getServerContact(for: uid)

		guard let serverValue else {
			if let localValue {
				return localValue
			} else {
				throw XError.noContactFound
			}
		}
		if let localValue {
			if localValue != serverValue {
				try await Store.shared.contactStore.updateAndSave(uid: uid) { model in
					model.update(with: serverValue)
				}
			}
		} else {
			try await Store.shared.contactStore.insert(serverValue)
		}
		return serverValue
	}

	@discardableResult
	public static func getOrCreate(for uids: [String], refatch: Bool) async throws -> [Contact] {
		guard let currentUserID = GroupAppStorage.shared.string(
			for: .auth(.currentUserID)
		) else {
			throw XError.noCurrentUserID
		}
		let memberIDs = uids.filter {
			!$0.isWhitespace && $0 != currentUserID
		}
		return try await withThrowingTaskGroup(of: Contact.self) { group -> [Contact] in
			memberIDs.forEach { uid in
				group.addTask {
					return try await ContactRepo.getOrCreate(
						for: uid,
						refatch: refatch
					)
				}
			}
			return try await group.map { $0 }.reduce(into: []) { $0.append($1) }
		}
	}

	public static func getServerContact(for uid: String) async throws -> Contact? {
		try await Firestore.firestore()
			.collection("users")
			.whereField("uid", isEqualTo: uid)
			.getDocuments().documents.first?
			.data(as: Contact.self)
	}
}
