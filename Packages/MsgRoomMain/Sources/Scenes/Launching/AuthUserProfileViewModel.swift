// © 2026 Aung Ko Min

import Core
import Database
import FirebaseAuth
import MediaPicker
import Services
import UIKit
import FirebaseMessaging

@MainActor
@Observable
public final class AuthUserProfileViewModel: ErrorPresenter {
    var editingUser: CurrentUserModel = .empty
    var currentUser: CurrentUserModel

    public var pickedPhoto: PickedPhoto? = nil
    public var isLoading = false
    private let repo: CurrentUserRepository

    public init(user: User) {
        editingUser = .init(user)
        currentUser = .init(user)
        repo = .init(.init(user))
    }

    public func shouldUpdateDisplayName(for user: CurrentUserModel) -> Bool {
        Auth
            .auth()
            .currentUser?
            .displayName != user.name.trimmed && user.name.isWhitespace == false
    }

    public func shouldUpdateProfile(for user: CurrentUserModel) -> Bool {
        shouldUpdateDisplayName(for: user) || shouldUpdateProfileImage()
    }

    public func shouldUpdateProfileImage() -> Bool {
        pickedPhoto != nil
    }

    public func isProfileComplete(for user: CurrentUserModel) -> Bool {
        user.name.isWhitespace == false
    }

    @concurrent
    public func applyUpdates(for snapshot: CurrentUserModel) async throws {
        guard let user = Auth.auth().currentUser else {
            return
        }

        let request = user.createProfileChangeRequest()
        request.displayName = snapshot.name.trimmed
        try await request.commitChanges()
        await setLoading(false)
    }

    @concurrent
    public func uploadImage(image: UIImage) async throws -> URL {
        guard
            let currentUser = Auth.auth().currentUser else
        {
            fatalError("explanation")
        }

        let imageUploader = ImageUploadingService()
        let url = try await imageUploader.uploadImage(
            image,
            size: .init(width: 100, height: 100),
            to: .user(uid: currentUser.uid),
        )
        let request = currentUser.createProfileChangeRequest()
        request.photoURL = url
        try await request.commitChanges()
        return url
    }

    public func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    public var hasChanges: Bool {
        editingUser != currentUser
    }

    public func saveProfile() async throws {
        setLoading(true)
        if let image = pickedPhoto?.uiImage {
            let url = try await uploadImage(image: image)
            editingUser.photoURL = url.absoluteString
            pickedPhoto = nil
        }
        try await applyUpdates(for: editingUser)
        try await repo.reload()
        currentUser = editingUser
        setLoading(false)
    }
}
