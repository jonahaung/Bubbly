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
	) async throws -> any ConversationRepresentable {
		switch indentifyConversationType(for: conID) {
		case .single:
			guard let currentUserID = GroupAppStorage.shared.string(
				for: .auth(.currentUserID)
			) else {
				throw XError.noCurrentUserID
			}
			let contactID = conID.replace(currentUserId ?? "", with: "")
			return try await getOrCreate(
				contactID: contactID,
				currentUserID: currentUserID,
				refetch: refetch
			)
		case .group:
			if !refetch, let existig: PGroup.SendableType = try await Store.shared.groupStore.fetch(uid: conID){
				return AnyConversation(.group(existig))
			}
			let reference = Firestore.firestore().collection("groups").whereField(
				"uid",
				isEqualTo: conID
			)
			let group: Database.Group? = try await FirestoreRepo.fetchSingle(
				query: reference
			)
			guard let group else {
				throw XError.noConversationGroupFound
			}
			return AnyConversation(.group(group))
		case .ai:
			return AnyConversation(.system(AI.system))
		}
	}

	public static func indentifyConversationType(for conID: String) -> ConversationType {
		if conID == "AI" {
			return .ai
		}
		return conID.contains("|") ? .single : .group
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
	) async throws -> any ConversationRepresentable {
		let contact = try await ContactRepo.getOrCreate(
			for: contactID,
			refatch: refetch
		)
		return AnyConversation(.contact(contact))
	}
}

public extension ConversationRepo {
	@MainActor
	static func get(conID: String) -> (any ConversationRepresentable)? {
		let context = Store.shared.appContainer.modelContainer.mainContext

		switch indentifyConversationType(for: conID) {
		case .group:
			var descriptor = FetchDescriptor<PGroup>(
				predicate: #Predicate<PGroup> { $0.uid == conID }
			)
			descriptor.fetchLimit = 1
			descriptor.includePendingChanges = true
			let model = try? context.fetch(descriptor).first
			guard let model else {
				return nil
			}
			let group = model.toSendable()
			return AnyConversation(.group(group))
		case .single:
			guard let currentUserID = GroupAppStorage.shared.string(
				for: .auth(.currentUserID)
			) else {
				return nil
			}
			let contactID = conID.replace(currentUserID, with: "")
			var descriptor = FetchDescriptor<PContact>(
				predicate: #Predicate<PContact> { $0.uid == contactID }
			)
			descriptor.fetchLimit = 1
			descriptor.includePendingChanges = true
			let model = try? context.fetch(descriptor).first
			guard let model else {
				return nil
			}
			let contact = model.toSendable()
			return AnyConversation(.contact(contact))
		case .ai:
			let ai = AI.system
			return AnyConversation(.system(ai))
		}
	}
	static func fetchMessages(
		conID: String,
		offset: Int? = nil,
		limit: Int? = nil
	) async throws -> [Message] {
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
		try await Store.shared.msgStore.delete(where: predicate)
	}
	static func lastMsg(conID: String) async throws -> Message? {
		let predicate = #Predicate<PMsg> { $0.conID == conID }
		var descriptor = FetchDescriptor<PMsg>(predicate: predicate)
		descriptor.sortBy = [.init(\.date, order: .reverse)]
		descriptor.fetchLimit = 1
		return try await Store.shared.msgStore.fetch(
			descriptor
		).first
	}
	static func firstMsg(conID: String) async throws -> Message? {
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
			.fetchCount(descriptor)
	}

	@MainActor
	static func getContacts(from conversation: any ConversationRepresentable) -> [Contact] {
		switch conversation.kind {
		case .contact(let contact):
			return [contact]
		case .group(_):
			let store = ContactStore.shared
			return conversation.members
				.map { store.contact(for: $0 )}
				.compactMap { $0 }
		case .system(let conversation):
			let store = ContactStore.shared
			return conversation.members
				.map { store.contact(for: $0 )}
				.compactMap { $0 }
		}

	}
}

public extension ConversationRepo {
	static func performUpdate(_ conversation: any ConversationRepresentable) async throws -> any ConversationRepresentable {
		switch conversation.kind {
		case .contact(let contact):
			return AnyConversation(.contact(try await ContactRepo.getOrCreate(for: contact.uid, refatch: false)))
		case .group(let group):
			try await ContactRepo.getOrCreate(for: group.members, refatch: false)
			return conversation
		case .system(var thisConversation):
//			_ = try await ContactRepo.getOrCreate(for: Array(conversation.members), refatch: true)
//
//			switch conversation.kind {
//			case .contact(let contact):
//				thisConversation.update(with: contact)
//			case .group(_):
//				let reference = Firestore.firestore().collection("groups").whereField(
//					"uid",
//					isEqualTo: conversation.uid
//				)
//				let group: Group? = try await FirestoreRepo.fetchSingle(
//					query: reference
//				)
//				if let group = group {
//					thisConversation.update(with: group)
//				}
//			case .system(_):
//				break
//			}
//			try await ContactStore.shared.fetchData()
			return conversation
		}
	}
}

public extension ConversationRepo {

	static func updateReceiveMsgs (for conID: String) async throws -> [Message] {
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
		let msgs = try await withThrowingTaskGroup(of: Message.self) { group in
			for var msg in unreadMsgs {
				group.addTask {
					msg.incomingStatus = .read
					try await msgStore.updateAndSave(uid: msg.uid) { model in
						model.update(with: msg)
					}
					return msg
				}
			}
			var result = [Message]()
			for try await msg in group {
				result.append(msg)
			}
			return result
		}
		return msgs
	}
}
