//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Database
import Services
import XUI

struct UserProfileSnapshot: Equatable {
    let currentUser: CurrentUserModel
    let originalUser: CurrentUserModel
    let hasPickedPhoto: Bool
}

@MainActor
protocol UserProfileRepository {
    var manager: UserProfileManager { get }
    func observe(initialUser: CurrentUserModel) async -> UserProfileSnapshot
    func refreshRemote() async throws -> UserProfileSnapshot
    func editName(_ value: String) async -> UserProfileSnapshot
    func setPickedPhoto(_ value: PickedPhoto?) async -> UserProfileSnapshot
    func resetChanges() async -> UserProfileSnapshot
    func saveChanges() async throws -> UserProfileSnapshot
    func signOut() async throws
    func removeDisplayName() async throws -> UserProfileSnapshot
    func latestSnapshot() async -> UserProfileSnapshot
}
