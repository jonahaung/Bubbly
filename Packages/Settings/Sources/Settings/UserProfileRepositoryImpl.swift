//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Core
import Database
import FirebaseAuth
import Services
import UIKit
import XUI
import Shared

@MainActor
struct UserProfileRepositoryImpl: UserProfileRepository {
    let manager: UserProfileManager

    func observe(initialUser: CurrentUserModel) async -> UserProfileSnapshot {
        manager.bootstrap(initialUser)
        return snapshot()
    }

    func refreshRemote() async throws -> UserProfileSnapshot {
        if let remote: CurrentUserModel = try await ContactHttpClient.shared.contact(
            uid: manager.currentUserRepository
                .model.uid)
        {
            manager.applyRemote(remote)
        }
        return snapshot()
    }

    func editName(_ value: String) async -> UserProfileSnapshot {
        manager.editName(value)
        return snapshot()
    }

    func setPickedPhoto(_ value: PickedPhoto?) async -> UserProfileSnapshot {
        manager.setPickedPhoto(value)
        return snapshot()
    }

    func resetChanges() async -> UserProfileSnapshot {
        manager.resetChanges()
        return snapshot()
    }

    func saveChanges() async throws -> UserProfileSnapshot {
        if let image = manager.pickedPhoto?.uiImage {
            let url = try await uploadImage(image)
            manager.updatePhotoURL(url.absoluteString)
        }
        try await applyDisplayName(manager.currentUser)
        try await manager.currentUserRepository.reload()
        await manager.markSaved()
        return snapshot()
    }

    func signOut() async throws {
        try Auth.auth().signOut()
    }

    func removeDisplayName() async throws -> UserProfileSnapshot {
        guard let user = Auth.auth().currentUser else {
            return snapshot()
        }
        let request = user.createProfileChangeRequest()
        request.displayName = nil
        try await request.commitChanges()
        manager.clearDisplayName()
        await manager.markSaved()
        try await manager.currentUserRepository.reload()
        return snapshot()
    }

    func latestSnapshot() async -> UserProfileSnapshot {
        snapshot()
    }

    private func applyDisplayName(_ user: CurrentUserModel) async throws {
        guard let authUser = Auth.auth().currentUser else {
            return
        }
        let request = authUser.createProfileChangeRequest()
        request.displayName = user.name.trimmed
        try await request.commitChanges()
    }

    private func uploadImage(_ image: UIImage) async throws -> URL {
        guard let authUser = Auth.auth().currentUser else {
            throw URLError(.userAuthenticationRequired)
        }
        guard let resized = image.resizedToFill(.init(width: 100, height: 100)) else {
            throw URLError(.userAuthenticationRequired)
        }
        let data = try MediaManager.shared.createData(
            from: resized
        )
        let model: CurrentUserModel = try await ContactHttpClient.shared
            .uploadProfilePhoto(data: data, contentType: "image/png")
        guard let url = URL(string: model.photoURL) else {
            throw URLError(.badURL)
        }
        let request = authUser.createProfileChangeRequest()
        request.photoURL = url
        try await request.commitChanges()
        return url
    }

    private func snapshot() -> UserProfileSnapshot {
        UserProfileSnapshot(
            currentUser: manager.currentUser,
            originalUser: manager.originalUser,
            hasPickedPhoto: manager.pickedPhoto != nil
        )
    }
}
