//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Database
import XUI

@MainActor
protocol ObserveUserProfileUseCase {
    var repository: UserProfileRepository { get }
    func execute() async -> UserProfileSnapshot
}

@MainActor
protocol RefreshUserProfileUseCase {
    func execute() async throws -> UserProfileSnapshot
}

@MainActor
protocol EditUserProfileNameUseCase {
    func execute(_ value: String) async -> UserProfileSnapshot
}

@MainActor
protocol SetUserProfilePhotoUseCase {
    func execute(_ value: PickedPhoto?) async -> UserProfileSnapshot
}

@MainActor
protocol ResetUserProfileChangesUseCase {
    func execute() async -> UserProfileSnapshot
}

@MainActor
protocol SaveUserProfileUseCase {
    func execute() async throws -> UserProfileSnapshot
}

@MainActor
protocol SignOutUserProfileUseCase {
    func execute() async throws
}

@MainActor
protocol RemoveUserProfileDisplayNameUseCase {
    func execute() async throws -> UserProfileSnapshot
}

@MainActor
protocol LatestUserProfileSnapshotUseCase {
    func execute() async -> UserProfileSnapshot
}

struct ObserveUserProfileUseCaseImpl: ObserveUserProfileUseCase {
    let repository: UserProfileRepository

    func execute() async -> UserProfileSnapshot {
        let initialUser = await repository.manager.currentUserRepository.model
        return await repository.observe(initialUser: initialUser)
    }
}

struct RefreshUserProfileUseCaseImpl: RefreshUserProfileUseCase {
    private let repository: UserProfileRepository

    init(repository: UserProfileRepository) {
        self.repository = repository
    }

    func execute() async throws -> UserProfileSnapshot {
        try await repository.refreshRemote()
    }
}

struct EditUserProfileNameUseCaseImpl: EditUserProfileNameUseCase {
    private let repository: UserProfileRepository

    init(repository: UserProfileRepository) {
        self.repository = repository
    }

    func execute(_ value: String) async -> UserProfileSnapshot {
        await repository.editName(value)
    }
}

struct SetUserProfilePhotoUseCaseImpl: SetUserProfilePhotoUseCase {
    private let repository: UserProfileRepository

    init(repository: UserProfileRepository) {
        self.repository = repository
    }

    func execute(_ value: PickedPhoto?) async -> UserProfileSnapshot {
        await repository.setPickedPhoto(value)
    }
}

struct ResetUserProfileChangesUseCaseImpl: ResetUserProfileChangesUseCase {
    private let repository: UserProfileRepository

    init(repository: UserProfileRepository) {
        self.repository = repository
    }

    func execute() async -> UserProfileSnapshot {
        await repository.resetChanges()
    }
}

struct SaveUserProfileUseCaseImpl: SaveUserProfileUseCase {
    private let repository: UserProfileRepository

    init(repository: UserProfileRepository) {
        self.repository = repository
    }

    func execute() async throws -> UserProfileSnapshot {
        try await repository.saveChanges()
    }
}

struct SignOutUserProfileUseCaseImpl: SignOutUserProfileUseCase {
    private let repository: UserProfileRepository

    init(repository: UserProfileRepository) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.signOut()
    }
}

struct RemoveUserProfileDisplayNameUseCaseImpl: RemoveUserProfileDisplayNameUseCase {
    private let repository: UserProfileRepository

    init(repository: UserProfileRepository) {
        self.repository = repository
    }

    func execute() async throws -> UserProfileSnapshot {
        try await repository.removeDisplayName()
    }
}

struct LatestUserProfileSnapshotUseCaseImpl: LatestUserProfileSnapshotUseCase {
    private let repository: UserProfileRepository

    init(repository: UserProfileRepository) {
        self.repository = repository
    }

    func execute() async -> UserProfileSnapshot {
        await repository.latestSnapshot()
    }
}
