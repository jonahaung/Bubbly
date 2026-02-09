//
//  AuthUserProfileViewModel.swift
//  Bubbly
//
//  Created by Aung Ko Min on 19/11/25.
//

import Core
import Database
import FirebaseAuth
import MediaPicker
import Services
import UIKit

@MainActor
@Observable
public final class AuthUserProfileViewModel: ErrorPresenter {
	var editingUser = CurrentUserModel.empty
	var currentUser: CurrentUserModel

	public var pickedPhoto: PickedPhoto?
	public var isLoading = false

	public init(user: User) {
		editingUser = .init(user)
		currentUser = .init(user)
	}

	public func shouldUpdateDisplayName(for user: CurrentUserModel) -> Bool {
		Auth
			.auth().currentUser?.displayName != user.name.trimmed && user.name.isWhitespace == false
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
			let currentUser = Auth.auth().currentUser
		else {
			fatalError()
		}
		let imageUploader = ImageUploadingService()
		let url = try await imageUploader.uploadImage(
			image,
			size: .init(width: 100, height: 100),
			to: .user(uid: currentUser.uid)
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
		reloadUser()
	}

	private func reloadUser() {
		if let user = Auth.auth().currentUser {
			currentUser = .init(user)
		}
	}

	public func updateRemoteUser() async throws {
		setLoading(true)
		let storage = GroupStorage.shared
		storage.save(currentUser.pushToken, for: .device(.deviceToken))
		storage.save(currentUser.uid, for: .auth(.currentUserID))
		storage.save(currentUser.publicKeyString, for: .security(.publicKey(id: currentUser.uid)))

		try await FirestoreRepo
			.update(
				value: currentUser.dictionary,
				collectionPath: .users,
				to: currentUser.uid
			)

		setLoading(false)
	}
}
