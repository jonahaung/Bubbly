//  DatabaseTests.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Testing
@testable import Database
import Foundation

final class DatabaseTests {
    @Test func groupDecodesLegacyDocumentWithoutTheme() throws {
        let data = """
        {
          "uid": "group-1",
          "name": "Bubbly",
          "createdDate": "2026-04-06T12:34:56.789Z",
          "photoURL": "https://example.com/group.png",
          "members": ["u1", "u2"],
          "createdBy": "u1"
        }
        """.data(using: .utf8)!

        let group = try JSONDecoder().decode(Group.self, from: data)

        #expect(group.uid == "group-1")
        #expect(group.theme == .default)
        #expect(group.seenMembers == nil)
    }

    @Test func groupDecodesLegacyStringCreatedDate() throws {
        let data = """
        {
          "uid": "group-3",
          "name": "Legacy",
          "createdDate": "2026-04-06T12:34:56.789Z",
          "members": ["u1"],
          "createdBy": "u1",
          "theme": {
            "bubbleColor": "default",
            "background": 0,
            "bubbleCornorRadius": 17
          }
        }
        """.data(using: .utf8)!

        let group = try JSONDecoder().decode(Group.self, from: data)

        #expect(group.createdDate.value == "2026-04-06T12:34:56.789Z")
    }

    @Test func groupRoundTripPreservesSeenMembers() throws {
        let original = Group(
            uid: "group-2",
            name: "Team",
            createdDate: .init("2026-04-06T12:34:56.789Z"),
            photoURL: "https://example.com/team.png",
            members: ["u1", "u2"],
            createdBy: "u1",
            theme: .init(),
            seenMembers: [.init(uid: "u2", msgId: "m1", date: "2026-04-06T12:35:56.789Z")]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Group.self, from: data)

        #expect(decoded == original)
    }
}
