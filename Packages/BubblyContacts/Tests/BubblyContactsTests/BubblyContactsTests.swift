//  BubblyContactsTests.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Testing
import Database
@testable import BubblyContacts

@MainActor
@Test
func loadsAndFiltersContacts() async {
    let model = ContactListViewModel(
        client: ContactListClient(
            load: {
                ContactListContent(
                    chatContacts: [
                        contact(uid: "2", name: "Zoë", mobile: "+222"),
                        contact(uid: "1", name: "Alice", mobile: "+111")
                    ],
                    phoneContacts: [],
                    groups: []
                )
            },
            syncContacts: {},
            syncGroups: {}
        )
    )

    await model.perform(.load)

    #expect(model.chatSections.map(\.id) == ["A", "Z"])
    #expect(model.chatSections.flatMap(\.contacts).map(\.name) == ["Alice", "Zoë"])

    model.searchText = "222"

    #expect(model.chatSections.map(\.id) == ["Z"])
    #expect(model.chatSections[0].contacts.map(\.name) == ["Zoë"])
}

@MainActor
@Test
func syncsBeforeReloadingContent() async {
    let recorder = OperationRecorder()
    let model = ContactListViewModel(
        client: ContactListClient(
            load: {
                await recorder.record("load")
                return .empty
            },
            syncContacts: {
                await recorder.record("sync")
            },
            syncGroups: {}
        )
    )

    await model.perform(.syncContacts)

    #expect(await recorder.values == ["sync", "load"])
}

@MainActor
@Test
func retainsContentWhenRefreshFails() async {
    let source = ContentSource()
    let model = ContactListViewModel(
        client: ContactListClient(
            load: {
                try await source.load()
            },
            syncContacts: {},
            syncGroups: {}
        )
    )

    await model.perform(.load)
    await source.fail()
    await model.perform(.refresh)

    #expect(model.chatSections.flatMap(\.contacts).map(\.name) == ["Alice"])
    #expect(model.errorMessage != nil)
    #expect(!model.isLoading)
}

private actor OperationRecorder {
    private(set) var values: [String] = []

    func record(_ value: String) {
        values.append(value)
    }
}

private actor ContentSource {
    private var shouldFail = false

    func fail() {
        shouldFail = true
    }

    func load() throws -> ContactListContent {
        if shouldFail {
            throw TestFailure()
        }
        return ContactListContent(
            chatContacts: [
                contact(uid: "1", name: "Alice", mobile: "+111")
            ],
            phoneContacts: [],
            groups: []
        )
    }
}

private struct TestFailure: Error {}

private func contact(
    uid: String,
    name: String,
    mobile: String
) -> Contact {
    Contact(
        uid: uid,
        name: name,
        mobile: mobile,
        photoURL: "",
        pushToken: "",
        publicKeyString: ""
    )
}
