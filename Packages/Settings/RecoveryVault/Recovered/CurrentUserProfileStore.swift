//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import MediaPicker
import Observation
import Services

@MainActor
@Observable
public final class CurrentUserProfileStore {
    private(set) var currentUser: CurrentUserModel = .empty
    private var originalUser: CurrentUserModel = .empty

    private(set) var pickedPhoto: PickedPhoto?
    let currentUserRepository: CurrentUserRepository

    public init(currentUserRepository: CurrentUserRepository) {
        self.currentUserRepository = currentUserRepository
    }

    func bootstrap(_ user: CurrentUserModel) {
        currentUser = user
        pickedPhoto = nil
    }

    func applyRemote(_ user: CurrentUserModel) {
        currentUser = user
        pickedPhoto = nil
    }

    func editName(_ value: String) {
        currentUser.name = value
    }

    func setPickedPhoto(_ value: PickedPhoto?) {
        pickedPhoto = value
    }

    func updatePhotoURL(_ value: String) {
        currentUser.photoURL = value
    }

    func clearDisplayName() {
        currentUser.name = ""
    }

    func markSaved() {
        currentUserRepository.update(currentUser)
        pickedPhoto = nil
    }

    func resetChanges() {
        currentUser = originalUser
        pickedPhoto = nil
    }
}
