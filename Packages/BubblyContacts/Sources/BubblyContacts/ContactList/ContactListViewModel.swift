//  ContactListViewModel.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Shared
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
        }
    }

    var chatSections: [ContactListSection] {
        ContactListSectionBuilder.sections(
            from: content.chatContacts,
            matching: searchText
        )
    }

    var phoneSections: [ContactListSection] {
        ContactListSectionBuilder.sections(
            from: content.phoneContacts,
            matching: searchText
        )
    }

    var groups: [Group] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return
            query.isEmpty
                ? content.groups
                : content.groups.filter {
                    $0.name.localizedStandardContains(query)
                }
    }

    private(set) var activeOperation: Operation?
    private(set) var errorMessage: String?

    var isLoading: Bool {
        activeOperation != nil
    }

    @ObservationIgnored private let client: ContactListClient
    @ObservationIgnored private var content: ContactListContent = .empty
    @ObservationIgnored private var operationTask: Task<Void, Never>?
    @ObservationIgnored private var operationID: UUID?

    var displayMode: ContactListDisplayMode = .chat

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
                    try Task.checkCancellation()
                    let content = try await client.load()
                    try Task.checkCancellation()
                    self?.finish(id: id, result: .success(content))
                case .syncContacts:
                    try await client.syncContacts()
                case .syncGroups:
                    let groups = try await GroupRepo.sync()
                    let memberIDs = groups.flatMap(\.members).removeDuplicates()
                    try await ContactRepo.getOrCreate(for: memberIDs, refatch: false)
                    Task { @MainActor in
                        self?.content.groups = groups
                    }
                }
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
}
