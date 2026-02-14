import Core
import Foundation
import SwiftData
import XUI

public enum ConversationPropertiesRepo {
	@discardableResult
	public static func getOrCreate(for conID: String) async throws -> ConversationProperties {
		let existing = try await Store.shared.conversationPropertiesStore?.fetch(uid: conID)
		if let existing {
			return existing
		}
		let newValue = ConversationProperties(uid: conID)
		try await Store.shared.conversationPropertiesStore?.insert(newValue)
		return newValue
	}

	@MainActor
	public static func getOrCreateMain(for conID: String) async -> ConversationProperties {
		// Hop into the Store actor to safely read its modelContainer
		let container = await Store.shared.modelContainer

		let predicate = #Predicate<PConversationProperties> { $0.uid == conID }
		var descriptor = FetchDescriptor<PConversationProperties>(predicate: predicate)
		descriptor.sortBy = [.init(\.uid, order: .forward)]

		let context = container?.mainContext
		let existing = try? context?.fetch(descriptor).first
		if let existing {
			return existing.toSendable()
		}
		let newValue = PConversationProperties(from: ConversationProperties(uid: conID))
		context?.insert(newValue)
		return newValue.toSendable()
	}
}
