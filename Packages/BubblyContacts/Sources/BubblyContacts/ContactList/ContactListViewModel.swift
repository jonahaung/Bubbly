//  ContactListViewModel.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database
import Foundation
import Observation

@MainActor
@Observable
final class ContactListViewModel {
    enum Operation: Sendable {
        case load
        case refresh
        case syncContacts
        case syncGroups
    }

    var searchText = "" {
        didSet {
            guard searchText != oldValue else {
                return
            }
            rebuildSections()
        }
    }

    private(set) var chatSections: [ContactListSection] = []
    private(set) var phoneSections: [ContactListSection] = []
    private(set) var groups: [Group] = []
    private(set) var activeOperation: Operation?
    private(set) var errorMessage: String?

    var isLoading: Bool {
        activeOperation != nil
    }

    @ObservationIgnored private let client: ContactListClient
    @ObservationIgnored private var content: ContactListContent = .empty
    @ObservationIgnored private var operationTask: Task<Void, Never>?
    @ObservationIgnored private var operationID: UUID?

    init(client: ContactListClient = .live) {
        self.client = client
    }

    func perform(_ operation: Operation) async {
        operationTask?.cancel()
        let id = UUID()
        operationID = id
        activeOperation = operation
        errorMessage = nil

        let task = Task { [weak self, client] in
            do {
                switch operation {
                case .load,
                     .refresh:
                    break
                case .syncContacts:
                    try await client.syncContacts()
                case .syncGroups:
                    try await client.syncGroups()
                }
                try Task.checkCancellation()
                let content = try await client.load()
                try Task.checkCancellation()
                self?.finish(id: id, result: .success(content))
            } catch is CancellationError {
                self?.finishCancellation(id: id)
            } catch {
                self?.finish(id: id, result: .failure(error))
            }
        }
        operationTask = task
        await task.value
    }

    func retry() async {
        await perform(.refresh)
    }

    func resolveContact(_ contact: Contact) async -> Contact? {
        errorMessage = nil
        do {
            return try await client.resolveContact(contact)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func cancel() {
        operationTask?.cancel()
        operationTask = nil
        operationID = nil
        activeOperation = nil
    }

    private func finish(
        id: UUID,
        result: Result<ContactListContent, any Error>
    ) {
        guard operationID == id else {
            return
        }
        operationTask = nil
        operationID = nil
        activeOperation = nil

        switch result {
        case let .success(content):
            self.content = content
            rebuildSections()
        case let .failure(error):
            errorMessage = error.localizedDescription
        }
    }

    private func finishCancellation(id: UUID) {
        guard operationID == id else {
            return
        }
        operationTask = nil
        operationID = nil
        activeOperation = nil
    }

    private func rebuildSections() {
        chatSections = ContactListSectionBuilder.sections(
            from: content.chatContacts,
            matching: searchText
        )
        phoneSections = ContactListSectionBuilder.sections(
            from: content.phoneContacts,
            matching: searchText
        )
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        groups = query.isEmpty
            ? content.groups
            : content.groups.filter {
                $0.name.localizedStandardContains(query)
            }
    }
}
