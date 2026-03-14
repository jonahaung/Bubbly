//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Foundation
import SwiftData
import XUI

public enum ConversationRepo {

	enum XError: Error {
		case noCurrentUserID
		case invalidConversationID
		case savingFailed
		case noConversationGroupFound
	}

	// MARK: - Conversation

	@discardableResult
	public static func getOrCreate(
		for conID: String,
		refetch: Bool
	) async throws -> Conversation {
		let kind = try await getConversationKind(for: conID, refetch: refetch)
		return Conversation(kind)
	}

	public static func getConversationKind(
		for conID: String,
		refetch: Bool
	) async throws -> ConversationKind {

		// Contact conversation
		if conID.contains("|") {
			let contactID = try resolveContactID(from: conID)
			let contact = try await ContactRepo.getOrCreate(uid: contactID, refetch: refetch)
			return .contact(contact)
		}

		// Local cache
		if !refetch,
		   let existing: PGroup.SendableType = try await Store.shared.groupStore?.fetch(uid: conID) {
			return .group(existing)
		}

		// Fetch from server
		let group: Database.Group? = try await FirestoreRepo.getModel(
			for: conID,
			collection: .groups,
			field: .uid
		)

		guard let group else {
			throw XError.noConversationGroupFound
		}

		let groupStore = await Store.shared.groupStore

		if try await groupStore?.exists(uid: conID) == true {
			try await groupStore?.updateAndSave(uid: conID) { model in
				model.update(from: group)
			}
		} else {
			try await groupStore?.insert(group)
		}

		try await ContactRepo.getOrCreate(for: group.members, refatch: refetch)

		return .group(group)
	}

	// MARK: - Helpers

	static func resolveContactID(from conID: String) throws -> String {

		var components = conID.components(separatedBy: "|")

		guard let currentUserID = GroupStorage.shared.string(for: .auth(.currentUserID)) else {
			throw XError.noCurrentUserID
		}

		components.removeAll { $0 == currentUserID }

		guard let contactID = components.first, !contactID.isEmpty else {
			throw XError.invalidConversationID
		}

		return contactID
	}

	// MARK: - Predicates

	static func messagesPredicate(for conID: String) -> Predicate<PMsg> {
		#Predicate<PMsg> { $0.conID == conID }
	}

	static func unreadMsgsPredicate(
		conID: String,
		currentUserID: String
	) -> Predicate<PMsg> {

		let readRaw = MsgIncomingStatus.read.rawValue

		return #Predicate<PMsg> {
			$0.conID == conID &&
			$0.senderID != currentUserID &&
			$0.incomingStatus < readRaw
		}
	}

	// MARK: - Descriptor

	static func descriptor(
		for conID: String,
		order: SortOrder,
		limit: Int? = nil,
		offset: Int? = nil
	) -> FetchDescriptor<PMsg> {

		var descriptor = FetchDescriptor<PMsg>(
			predicate: messagesPredicate(for: conID)
		)

		descriptor.sortBy = [.init(\.date, order: order)]

		if let limit {
			descriptor.fetchLimit = limit
		}

		if let offset {
			descriptor.fetchOffset = offset
		}

		return descriptor
	}

	// MARK: - Messages

	public static func fetchMessages(
		conID: String,
		offset: Int? = nil,
		limit: Int? = nil
	) async throws -> [Message] {

		guard let msgStore = await Store.shared.msgStore else { return [] }

		let descriptor = descriptor(
			for: conID,
			order: .reverse,
			limit: limit,
			offset: offset
		)

		let snapshots = try await msgStore.fetch(descriptor)

		return snapshots.reversed()
	}

	public static func deleteMessages(conID: String) async throws {
		try await Store.shared.msgStore?.delete(where: messagesPredicate(for: conID))
	}

	public static func lastMsg(conID: String) async throws -> Message? {

		guard let msgStore = await Store.shared.msgStore else { return nil }

		let descriptor = descriptor(for: conID, order: .reverse, limit: 1)

		return try await msgStore.fetch(descriptor).first
	}

	public static func firstMsg(conID: String) async throws -> Message? {

		guard let msgStore = await Store.shared.msgStore else { return nil }

		let descriptor = descriptor(for: conID, order: .forward, limit: 1)

		return try await msgStore.fetch(descriptor).first
	}

	public static func totalMsgsCount(conID: String) async throws -> Int {

		guard let msgStore = await Store.shared.msgStore else { return 0 }

		let descriptor = FetchDescriptor<PMsg>(
			predicate: messagesPredicate(for: conID)
		)

		return try await msgStore.fetchCount(descriptor)
	}

	public static func countUnreadMsgs(
		conID: String,
		currentUserID: String
	) async throws -> Int {

		guard let msgStore = await Store.shared.msgStore else { return 0 }

		let predicate = unreadMsgsPredicate(
			conID: conID,
			currentUserID: currentUserID
		)

		let descriptor = FetchDescriptor<PMsg>(predicate: predicate)

		return try await msgStore.fetchCount(descriptor)
	}

	public static func fetchUnreadMessages(
		conID: String,
		limit: Int? = nil,
		currentUserID: String
	) async throws -> [Message] {

		guard let msgStore = await Store.shared.msgStore else { return [] }

		let predicate = unreadMsgsPredicate(
			conID: conID,
			currentUserID: currentUserID
		)

		var descriptor = FetchDescriptor<PMsg>(predicate: predicate)

		if let limit {
			descriptor.fetchLimit = limit
		}

		descriptor.sortBy = [.init(\.date, order: .forward)]

		return try await msgStore.fetch(descriptor)
	}

	public static func updateReceiveMsgs(
		for conID: String,
		currentUserID: String
	) async throws -> [Message] {

		let unreadMsgs = try await fetchUnreadMessages(
			conID: conID,
			currentUserID: currentUserID
		)

		guard !unreadMsgs.isEmpty else { return [] }

		guard let msgStore = await Store.shared.msgStore else { return [] }

		return try await AsyncOrderedStream.mapOrdered(inputs: unreadMsgs) { msg in

			var updated = msg
			updated.incomingStatus = .read

			try await msgStore.updateAndSave(uid: updated.uid) { model in
				model.update(from: updated)
			}

			return updated
		}
	}

	// MARK: - Search

	public static func search(
		from name: String,
		currentUserId: String
	) async throws -> Conversation? {

		if let contact = try await ContactRepo.search(named: name) {
			return Conversation(.contact(contact))
		}

		if let group = try await ContactRepo.searchGroup(named: name) {
			return Conversation(.group(group))
		}

		return nil
	}
}
