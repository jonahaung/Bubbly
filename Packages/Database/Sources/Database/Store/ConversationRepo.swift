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

	@discardableResult
	public static func getOrCreate(for conID: String, refetch: Bool) async throws -> Conversation {
		let kind = try await getConversationKind(for: conID, refetch: refetch)
		let properties = try await ConversationPropertiesRepo.getOrCreate(for: conID)
		return Conversation(kind, properties: properties)
	}

	public static func getConversationKind(for conID: String,
	                                       refetch: Bool) async throws -> ConversationKind
	{
		if conID.contains("|") {
			let contactID = try resolveContactID(from: conID)
			let contact = try await ContactRepo.getOrCreate(for: contactID, refetch: refetch)
			return .contact(contact)
		}

		if !refetch, let existing: PGroup.SendableType = try await Store.shared.groupStore?.fetch(
			uid: conID
		) {
			return .group(existing)
		}

		let group: Database.Group? = try await FirestoreRepo.getModel(
			for: conID,
			collection: .groups,
			field: .uid
		)
		guard let group else {
			throw XError.noConversationGroupFound
		}

		if try await Store.shared.groupStore?.exists(uid: conID) == false {
			try await Store.shared.groupStore?.insert(group)
		} else {
			try await Store.shared.groupStore?.updateAndSave(uid: conID) { model in
				model.update(from: group)
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

	static func statusNotPredicate(for status: MsgIncomingStatus) -> Predicate<PMsg> {
		let readRawValue = status.rawValue
		return #Predicate<PMsg> { $0.incomingStatus < readRawValue }
	}

	static func senderIDNotPredicate(for uid: String) -> Predicate<PMsg> {
		#Predicate<PMsg> { $0.senderID != uid }
	}

	static func descriptor(for conID: String,
	                       order: SortOrder,
	                       limit: Int? = nil,
	                       offset: Int? = nil) -> FetchDescriptor<PMsg>
	{
		var descriptor = FetchDescriptor<PMsg>(predicate: messagesPredicate(for: conID))
		descriptor.sortBy = [.init(\.date, order: order)]
		if let limit { descriptor.fetchLimit = limit }
		if let offset { descriptor.fetchOffset = offset }
		return descriptor
	}

	public static func fetchMessages(conID: String,
	                                 offset: Int? = nil,
	                                 limit: Int? = nil) async throws -> [Message]
	{
		let descriptor = descriptor(for: conID, order: .reverse, limit: limit, offset: offset)
		let snapshots = try await Store.shared.msgStore?.fetch(descriptor) ?? []
		return snapshots.reversed()
	}

	public static func deleteMessages(conID: String) async throws {
		try await Store.shared.msgStore?.delete(where: messagesPredicate(for: conID))
	}

	public static func lastMsg(conID: String) async throws -> Message? {
		let descriptor = descriptor(for: conID, order: .reverse, limit: 1)
		return try await Store.shared.msgStore?.fetch(descriptor).first
	}

	public static func firstMsg(conID: String) async throws -> Message? {
		let descriptor = descriptor(for: conID, order: .forward, limit: 1)
		return try await Store.shared.msgStore?.fetch(descriptor).first
	}

	public static func totalMsgsCount(conID: String) async throws -> Int {
		let descriptor = FetchDescriptor<PMsg>(predicate: messagesPredicate(for: conID))
		return try await Store.shared.msgStore?.fetchCount(descriptor) ?? 0
	}

	public static func countUnreadMsgs(conID: String, currentUserID: String) async throws -> Int {
		let predicate = unreadMsgsPredicate(conID: conID, currentUserID: currentUserID)
		let descriptor = FetchDescriptor<PMsg>(predicate: predicate)
		return try await Store.shared.msgStore?.fetchCount(descriptor) ?? 0
	}

	public static func unreadMsgsPredicate(conID: String,
	                                       currentUserID: String) -> Predicate<PMsg>
	{
		let conPredicate = messagesPredicate(for: conID)
		let recipientPredicate = senderIDNotPredicate(for: currentUserID)
		let statusPredicate = statusNotPredicate(for: .read)

		let predicate = #Predicate<PMsg> {
			conPredicate.evaluate($0) && recipientPredicate.evaluate($0) && statusPredicate
				.evaluate($0)
		}
		return predicate
	}

	public static func fetchUnreadMessages(conID: String,
	                                       limit: Int? = nil,
	                                       currentUserID: String) async throws -> [Message]
	{
		let predicate = unreadMsgsPredicate(conID: conID, currentUserID: currentUserID)
		var descriptor = FetchDescriptor<PMsg>(predicate: predicate)
		if let limit {
			descriptor.fetchLimit = limit
		}
		descriptor.sortBy = [.init(\.date, order: .forward)]
		return try await Store.shared.msgStore?.fetch(descriptor) ?? []
	}

	public static func updateReceiveMsgs(for conID: String,
	                                     currentUserID: String) async throws -> [Message]
	{
		let unreadMsgs = try await fetchUnreadMessages(conID: conID, currentUserID: currentUserID)
		guard !unreadMsgs.isEmpty else { return [] }

		let msgStore = await Store.shared.msgStore

		// Transform each message and let mapOrdered collect the results.
		return try await AsyncOrderedStream.mapOrdered(inputs: unreadMsgs) { msg in
			var msg = msg
			msg.incomingStatus = .read
			try await msgStore?.updateAndSave(uid: msg.uid) { model in
				model.update(from: msg)
			}
			return msg
		}
	}

	public static func search(form name: String,
	                          currentUserId: String) async throws -> Conversation?
	{
		if let contact = try await ContactRepo.search(named: name) {
			await Conversation(
				.contact(contact),
				properties: ConversationPropertiesRepo.getOrCreateMain(
					for: ConversationIDGenerator.generate(
						currentUserId,
						contact.uid
					)
				)
			)
		} else if let group = try await ContactRepo.searchGroup(named: name) {
			await Conversation(
				.group(group),
				properties: ConversationPropertiesRepo.getOrCreateMain(
					for: ConversationIDGenerator.generate(
						currentUserId,
						group.uid
					)
				)
			)
		} else {
			nil
		}
	}
}
