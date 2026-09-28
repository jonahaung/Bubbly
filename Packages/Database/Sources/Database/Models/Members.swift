//  Members.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import Shared

public struct Members: Sendable, Hashable {
    public let members: [Contact]
    public init(members: [Contact]) {
        self.members = members
    }

    public func contact(for uid: String) -> Contact? {
        members.first(where: { $0.uid == uid })
    }
}
