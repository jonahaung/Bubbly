//
//  ConversationPropertiesRepo.swift
//  Database
//
//  Created by Aung Ko Min on 10/12/25.
//

import Core
import Foundation
import SwiftData
import XUI

public enum ConversationPropertiesRepo {
	@discardableResult
	public static func getOrCreate(for conID: String) async throws -> ConversationProperties {
		let existing = try await Store.shared.conversationPropertiesStore.fetch(uid: conID)
		if let existing {
			return existing
		}
		let newValue = ConversationProperties(uid: conID)
		try await Store.shared.conversationPropertiesStore.insert(newValue)
		return newValue
	}

	@MainActor
	public static func getOrCreateMain(for conID: String) -> ConversationProperties {
		let predicate = #Predicate<PConversationProperties> { $0.uid == conID }
		var descriptor = FetchDescriptor<PConversationProperties>(predicate: predicate)
		descriptor.sortBy = [.init(\.uid, order: .forward)]
		let existing = try? Store.shared.modelContainer.mainContext.fetch(descriptor).first
		if let existing {
			return existing.toSendable()
		}
		let newValue = PConversationProperties(from: ConversationProperties(uid: conID))
		Store.shared.modelContainer.mainContext.insert(newValue)
		return newValue.toSendable()
	}
}
