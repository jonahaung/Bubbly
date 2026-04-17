import Database

@MainActor
struct ContactProfileRepositoryImpl: ContactProfileRepository {
    private let manager: ContactProfileManager

    init(manager: ContactProfileManager) {
        self.manager = manager
    }

    func loadInitial() async throws -> ContactProfileSnapshot {
        let contact = try await loadContact(refetch: false)
        let properties = try await loadProperties(for: contact, refetch: false)
        manager.setContact(contact)
        manager.setProperties(properties)
        manager.setLoading(false)
        manager.setError(nil)
        return snapshot()
    }

    func refresh() async throws -> ContactProfileSnapshot {
        let contact = try await loadContact(refetch: true)
        let properties = try await loadProperties(for: contact, refetch: true)
        manager.setContact(contact)
        manager.setProperties(properties)
        manager.setLoading(false)
        manager.setError(nil)
        return snapshot()
    }

    func updateContact(_ contact: Contact) async throws -> ContactProfileSnapshot {
        manager.setContact(contact)
		if try await Store.shared.contactStore?.updateAndSave(uid: contact.uid, { model in
			model.merge(from: contact)
		}) == nil {
            try await Store.shared.contactStore?.insert(contact)
        }
        manager.setLoading(false)
        manager.setError(nil)
        return snapshot()
    }

    func updateProperties(_ properties: ConversationProperties) async throws -> ContactProfileSnapshot {
        manager.setProperties(properties)
		if try await Store.shared.conversationPropertiesStore?
			.updateAndSave(uid: properties.uid, { model in
				model.update(from: properties)
			}) == nil {
            try await Store.shared.conversationPropertiesStore?.insert(properties)
        }
        manager.setLoading(false)
        manager.setError(nil)
        return snapshot()
    }

    func deleteMessages() async throws -> ContactProfileSnapshot {
        try await MsgRepo.deleteMessages(conID: manager.properties.uid)
        manager.setDeletingMessages(false)
        manager.setError(nil)
        return snapshot()
    }

    func latestSnapshot() async -> ContactProfileSnapshot {
        snapshot()
    }

    private func snapshot() -> ContactProfileSnapshot {
        .init(
            contact: manager.contact,
            properties: manager.properties,
            isLoading: manager.isLoading,
            isDeletingMessages: manager.isDeletingMessages,
            error: manager.error
        )
    }

    private func loadContact(refetch: Bool) async throws -> Contact {
        do {
            return try await ContactRepo.getOrCreate(uid: manager.contact.uid, refetch: refetch)
        } catch {
            if refetch {
                throw error
            }
            return manager.contact
        }
    }

    private func loadProperties(for contact: Contact, refetch: Bool) async throws -> ConversationProperties {
        try await ConversationPropertiesRepo.getOrCreate(
            for: Conversation(.contact(contact)).uid,
            refetch: refetch
        )
    }
}
