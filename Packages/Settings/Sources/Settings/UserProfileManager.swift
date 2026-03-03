//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import MediaPicker
import Observation
import Services

@MainActor
@Observable
final class UserProfileManager {
    private(set) var currentUser: CurrentUserModel
    private(set) var originalUser: CurrentUserModel

    private(set) var pickedPhoto: PickedPhoto?
    let currentUserRepository: CurrentUserRepository

    init(currentUserRepository: CurrentUserRepository) {
        currentUser = .empty
        originalUser = .empty
        self.currentUserRepository = currentUserRepository
    }

    func bootstrap(_ user: CurrentUserModel) {
        currentUser = user
        originalUser = user
        pickedPhoto = nil
    }

    func applyRemote(_ user: CurrentUserModel) {
        currentUser = user
        originalUser = user
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

    func markSaved() async {
        await currentUserRepository.update(currentUser)
        originalUser = currentUser
        pickedPhoto = nil
    }

    func resetChanges() {
        currentUser = originalUser
        pickedPhoto = nil
    }
}
