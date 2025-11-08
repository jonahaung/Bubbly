//
//  ConversationRepo.swift
//  Database
//
//  Created by Aung Ko Min on 28/10/25.
//

import Foundation
import SwiftData
import Core
import XUI

public enum ConversationRepo {

	enum XError: Error {
		case noCurrentUserID
		case invalidConversationID
		case savingFailed
		case noConversationGroupFound
	}

	@discardableResult
	public static func getOrCreate(for conID: String, refetch: Bool) async throws -> any ConversationRepresentable {
		let kind = try await getConversationKind(for: conID, refetch: refetch)
		return AnyConversation(kind)
	}

	public static func getConversationKind(for conID: String, refetch: Bool) async throws -> ConversationKind {
		if conID == AnyConversation(.system(AI.contact)).uid {
			let contact = try await ContactRepo.getOrCreate(for: AI.contact.uid, refetch: false)
			return .system(contact)
		}

		if conID.contains("|") {
			let contactID = try resolveContactID(from: conID)
			let contact = try await ContactRepo.getOrCreate(for: contactID, refetch: refetch)
			return .contact(contact)
		}

		if !refetch, let existing: PGroup.SendableType = try await Store.shared.groupStore.fetch(uid: conID) {
			return .group(existing)
		}

		let group: Database.Group? = try await FirestoreRepo.getModel(for: conID, collection: .groups, field: .uid)
		guard let group else {
			throw XError.noConversationGroupFound
		}

		if try await Store.shared.groupStore.exists(uid: conID) == false {
			try await Store.shared.groupStore.insert(group)
		} else {
			try await Store.shared.groupStore.updateAndSave(uid: conID) { model in
				model.update(with: group)
			}
		}
		try await ContactRepo.getOrCreate(for: group.members, refatch: refetch)
		return .group(group)
	}

	static func resolveContactID(from conID: String) throws -> String {
		var components = conID.components(separatedBy: "|")
		guard let currentUserID = GroupStorage.shared.string(for: .auth(.currentUserID)) else {
			throw XError.noCurrentUserID
		}
		components.removeAll(where: { $0 == currentUserID })
		guard let contactID = components.first, !contactID.isEmpty else {
			throw XError.noConversationGroupFound
		}
		return contactID
	}

	static func messagesPredicate(for conID: String) -> Predicate<PMsg> {
		#Predicate<PMsg> { $0.conID == conID }
	}

	static func descriptor(
		for conID: String,
		order: SortOrder,
		limit: Int? = nil,
		offset: Int? = nil
	) -> FetchDescriptor<PMsg> {
		var descriptor = FetchDescriptor<PMsg>(predicate: messagesPredicate(for: conID))
		descriptor.sortBy = [.init(\.date, order: order)]
		if let limit { descriptor.fetchLimit = limit }
		if let offset { descriptor.fetchOffset = offset }
		return descriptor
	}

	public static func createConversationID(for one: String, two: String) -> String {
		one > two ? two + "|" + one : one + "|" + two
	}

	public static func fetchMessages(
		conID: String,
		offset: Int? = nil,
		limit: Int? = nil
	) async throws -> [Message] {
		let descriptor = descriptor(for: conID, order: .reverse, limit: limit, offset: offset)
		let snapshots = try await Store.shared.msgStore.fetch(descriptor)
		return snapshots.reversed()
	}

	public static func deleteMessages(conID: String) async throws {
		try await Store.shared.msgStore.delete(where: messagesPredicate(for: conID))
	}

	public static func lastMsg(conID: String) async throws -> Message? {
		let descriptor = descriptor(for: conID, order: .reverse, limit: 1)
		return try await Store.shared.msgStore.fetch(descriptor).first
	}

	public static func firstMsg(conID: String) async throws -> Message? {
		let descriptor = descriptor(for: conID, order: .forward, limit: 1)
		return try await Store.shared.msgStore.fetch(descriptor).first
	}

	public static func totalMsgsCount(conID: String) async throws -> Int {
		let descriptor = FetchDescriptor<PMsg>(predicate: messagesPredicate(for: conID))
		return try await Store.shared.msgStore.fetchCount(descriptor)
	}

	public static func updateReceiveMsgs(for conID: String) async throws -> [Message] {
		guard let currentUserID = GroupStorage.shared.string(for: .auth(.currentUserID)) else {
			throw XError.noCurrentUserID
		}

		let conPredicate = #Predicate<PMsg> { $0.conID == conID }
		let recipientPredicate = #Predicate<PMsg> { $0.senderID != currentUserID }
		let readRawValue = MsgIncomingStatus.read.rawValue
		let statusPredicate = #Predicate<PMsg> { $0.incomingStatus < readRawValue }

		let predicate = #Predicate<PMsg> {
			conPredicate.evaluate($0) &&
			recipientPredicate.evaluate($0) &&
			statusPredicate.evaluate($0)
		}

		var descriptor = FetchDescriptor<PMsg>(predicate: predicate)
		descriptor.sortBy = [.init(\.date, order: .forward)]

		let unreadMsgs = try await Store.shared.msgStore.fetch(descriptor)
		guard !unreadMsgs.isEmpty else { return [] }

		let msgStore = Store.shared.msgStore

		var updated: [Message] = []
		updated.reserveCapacity(unreadMsgs.count)

		for var msg in unreadMsgs {
			msg.incomingStatus = .read
			try await msgStore.updateAndSave(uid: msg.uid) { model in
				model.update(with: msg)
			}
			updated.append(msg)
		}

		return updated
	}
}
