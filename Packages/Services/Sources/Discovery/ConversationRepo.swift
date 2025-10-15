//
//  ConversationRepo.swift
//  Services
//
//  Created by Aung Ko Min on 25/5/25.
//

import Foundation
import Database
import SwiftData
import Core
import FirebaseFirestore
import XUI

public struct ConversationRepo {

	enum XError: Error {
		case noCurrentUserID
		case invalidConversationID
		case savingFailed
		case noConversationGroupFound
	}
	public init() {}

	@discardableResult
	public static func getOrCreate(
		for conID: String,
		refetch: Bool
	) async throws -> ConversationSnapshot {

		if !refetch, let existig = try await Store.shared.conversationStore.fetch(uid: conID) {
			return existig
		}
		switch indentifyConversationType(for: conID) {
		case .single:
			guard let currentUserID = GroupAppStorage.shared.string(
				for: .auth(.currentUserID)
			) else {
				throw XError.noCurrentUserID
			}
			let components = conID.components(separatedBy: "|")
			guard components.count == 2,
				  let contactID = components.first(
					where: { $0 != currentUserID }
				  ) else {
				throw XError.invalidConversationID
			}
			return try await getOrCreate(
				contactID: contactID,
				currentUserID: currentUserID,
				refetch: refetch
			)
		case .group:
			let reference = Firestore.firestore().collection("groups").whereField(
				"uid",
				isEqualTo: conID
			)
			let group: Group? = try await FirestoreRepo.fetchSingle(
				query: reference
			)
			guard let group else {
				throw XError.noConversationGroupFound
			}
			let conversation = ConversationSnapshot(group: group)
			if try await Store.shared.conversationStore
				.isExisted(uid: conID) == false {
				try await Store.shared.conversationStore.insert(conversation)
			}
			return conversation
		}
	}

	public static func indentifyConversationType(for conID: String) -> ConversationType {
		let components = conID.components(separatedBy: "|")
		return components.count > 1 ? .single : .group
	}
}

public extension ConversationRepo {
	static func createConversationID(for one: String, two: String) -> String {
		one > two ? two+"|"+one : one+"|"+two
	}
	static func getOrCreate(
		contactID: String,
		currentUserID: String,
		refetch: Bool
	) async throws -> ConversationSnapshot {
		let contact = try await ContactRepo.getOrCreate(
			for: contactID,
			refatch: refetch
		)
		return try await getOrCreate(
			for: contact,
			currentUserID: currentUserID
		)
	}
	static func getOrCreate(
		for contact: ContactSnapshot,
		currentUserID: String
	) async throws -> ConversationSnapshot {
		let conversationID = createConversationID(
			for: contact.uid,
			two: currentUserID
		)
		if let existig = try await Store.shared.conversationStore.fetch(uid: conversationID) {
			try await Store.shared.conversationStore
				.updateAndSave(uid: conversationID) { model in
					model.update(with: contact)
				}
			return existig
		}
		let snapshot = ConversationSnapshot(
			uid: conversationID,
			name: contact.name,
			type: .single,
			createdDate: .now,
			photoURL: contact.photoURL,
			members: [contact.uid]
		)
		try await Store.shared.conversationStore.insert(snapshot)
		return snapshot
	}
}

public extension ConversationRepo {
	@MainActor
	static func get(conID: String) -> ConversationSnapshot? {
		let context = Store.shared.appContainer.modelContainer.mainContext
		var descriptor = FetchDescriptor<PConversation>(
			predicate: #Predicate<PConversation> { $0.uid == conID }
		)
		descriptor.fetchLimit = 1
		descriptor.includePendingChanges = false
		let model = try? context.fetch(descriptor).first
		guard let model else {
			return nil
		}
		return .init(model: model)
	}
	static func fetchMessages(
		conID: String,
		offset: Int? = nil,
		limit: Int? = nil
	) async throws -> [MsgSnapshot] {
		let predicate = #Predicate<PMsg> { $0.conID == conID }
		var descriptor = FetchDescriptor<PMsg>(predicate: predicate)
		descriptor.sortBy = [.init(\.date, order: .reverse)]
		if let offset {
			descriptor.fetchOffset = offset
		}
		if let limit {
			descriptor.fetchLimit = limit
		}
		let snapshots = try await Store.shared.msgStore.fetch(
			descriptor
		)
		return snapshots.reversed()
	}
	static func deleteMessages(
		conID: String
	) async throws {
		let predicate = #Predicate<PMsg> { $0.conID == conID }
		try await Store.shared.msgStore.delete(predicate)
	}
	static func lastMsg(conID: String) async throws -> MsgSnapshot? {
		let predicate = #Predicate<PMsg> { $0.conID == conID }
		var descriptor = FetchDescriptor<PMsg>(predicate: predicate)
		descriptor.sortBy = [.init(\.date, order: .reverse)]
		descriptor.fetchLimit = 1
		return try await Store.shared.msgStore.fetch(
			descriptor
		).first
	}
	static func firstMsg(conID: String) async throws -> MsgSnapshot? {
		let predicate = #Predicate<PMsg> { $0.conID == conID }
		var descriptor = FetchDescriptor<PMsg>(predicate: predicate)
		descriptor.sortBy = [.init(\.date, order: .forward)]
		descriptor.fetchLimit = 1
		return try await Store.shared.msgStore.fetch(
			descriptor
		).first
	}
	static func totalMsgsCount(conID: String) async throws -> Int {
		let predicate = #Predicate<PMsg> { $0.conID == conID }
		let descriptor = FetchDescriptor<PMsg>(predicate: predicate)
		return try await Store.shared.msgStore
			.fetchCount(descriptor: descriptor)
	}

	@MainActor
	static func getContacts(from conversation: ConversationSnapshot) -> [ContactSnapshot] {
		let store = ContactStore.shared
		return conversation.members
			.map { store.contact(for: $0 )}
			.compactMap { $0 }
	}
}

public extension ConversationRepo {
	static func performUpdate(_ conversation: ConversationSnapshot) async throws -> ConversationSnapshot {
		guard let currentUserID = GroupAppStorage.shared.string(
			for: .auth(.currentUserID)
		) else {
			throw XError.noCurrentUserID
		}
		var thisConversation = conversation
		let contacts = try await ContactRepo.getOrCreate(for: Array(conversation.members), refatch: true)

		switch conversation.type {
		case .single:
			if let contact = contacts.first(
				where: { $0.uid
					!= currentUserID }) {
				thisConversation.update(with: contact)
				try await Store.shared.conversationStore
					.updateAndSave(uid: conversation.uid) { model in
						model.update(with: contact)
					}
			}
		case .group:
			let reference = Firestore.firestore().collection("groups").whereField(
				"uid",
				isEqualTo: conversation.uid
			)
			let group: Group? = try await FirestoreRepo.fetchSingle(
				query: reference
			)
			if let group = group {
				thisConversation.update(with: group)
			}
		}
		try await ContactStore.shared.fetchData()
		return thisConversation
	}
}

public extension ConversationRepo {

	static func updateReceiveMsgs (for conID: String) async throws -> [MsgSnapshot] {
		guard let currentUserID = GroupAppStorage.shared.string(
			for: .auth(.currentUserID)
		) else {
			throw XError.noCurrentUserID
		}
		let conPredicate =  #Predicate<PMsg> {
			$0.conID == conID
		}
		let recipientPredicate =  #Predicate<PMsg> {
			$0.senderID != currentUserID
		}
		let readRawValue = MsgIncomingStatus.read.rawValue
		let statusPredicate =  #Predicate<PMsg> {
			$0.incomingStatus < readRawValue
		}
		let predicate = #Predicate<PMsg> {
			conPredicate.evaluate($0) && recipientPredicate.evaluate($0) && statusPredicate.evaluate($0)
		}
		var descriptor = FetchDescriptor<PMsg>(predicate: predicate)
		descriptor.sortBy = [.init(\.date, order: .forward)]

		let unreadMsgs = try await Store.shared.msgStore.fetch(
			descriptor
		)
		let msgStore = Store.shared.msgStore
		let msgs = try await withThrowingTaskGroup(of: MsgSnapshot.self) { group in
			for var msg in unreadMsgs {
				group.addTask {
					msg.incomingStatus = .read
					try await msgStore.updateAndSave(uid: msg.uid) { model in
						model.update(with: msg)
					}
					return msg
				}
			}
			var result = [MsgSnapshot]()
			for try await msg in group {
				result.append(msg)
			}
			return result
		}
		return msgs
	}
}
