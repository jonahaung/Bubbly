//
//  ConversationRepresentable.swift
//  Database
//
//  Created by Aung Ko Min on 23/10/25.
//

import Core
import Foundation
import XUI

public protocol ConversationRepresentable: Codable, Sendable, Hashable, Equatable, UIdentifiable {
	var uid: String { get }
	var kind: ConversationKind { get set }
	var name: String { get }
	var photoURL: String { get }
	var members: [String] { get }
	var theme: ConversationTheme { get }
	var seenMembers: [SeenMember] { get set }
	var lastMsgID: String? { get set }

	init(_ kind: ConversationKind)
	mutating func saveChanges() async throws
	@concurrent mutating func reload(refetch: Bool) async throws -> Self
}

extension ConversationRepresentable {
	@concurrent
	public func reload(refetch: Bool = false) async throws -> Self {
		guard
			let updated = try await ConversationRepo
				.getOrCreate(for: uid, refetch: refetch) as? Self
		else {
			throw ConversationError.invalidType
		}
		return updated
	}

	public mutating func saveChanges() async throws {
		switch kind {
		case .contact(let contact):
			guard self != .init(.contact(contact)) else { return }
			let merged = contact.merging(from: self)
			try await Store.shared.contactStore.updateAndSave(uid: contact.uid) {
				$0.update(with: merged)
			}
			self = .init(.contact(merged))
		case .group(let group):
			guard self != .init(.group(group)) else { return }
			try await Store.shared.groupStore.updateAndSave(uid: group.uid) {
				$0.update(with: self)
			}
		case .system(let contact):
			guard self != .init(.system(contact)) else { return }
			let merged = contact.merging(from: self)
			try await Store.shared.contactStore.updateAndSave(uid: contact.uid) {
				$0.update(with: merged)
			}
			self = .init(.contact(merged))
		}
	}
}

enum ConversationError: Error {
	case invalidType
}
