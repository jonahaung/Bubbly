//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Foundation
import SwiftUI

@MainActor
public protocol ContactsRepositoryProtocol: Observable, Sendable {
    var contacts: [Contact] { get set }
    var groups: [Database.Group] { get set }

    @concurrent
    func fetchData() async throws
    @concurrent
    func syncGroups(currentUserId: String) async throws
    @concurrent
    func syncContacts() async throws
    func contact(for uid: String) -> Contact?
    @concurrent
    func delete(uid: String) async throws
}
