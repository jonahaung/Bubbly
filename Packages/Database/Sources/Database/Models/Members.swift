//
//  Members.swift
//  Database
//
//  Created by Aung Ko Min on 20/5/26.
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
