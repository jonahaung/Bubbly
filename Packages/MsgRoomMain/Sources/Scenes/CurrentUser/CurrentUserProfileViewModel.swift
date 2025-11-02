//
//  CurrentUserProfileViewModel.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 24/5/25.
//

import UIKit
import Database
import FirebaseAuth
import Core
import Services
import MediaPicker

@MainActor
@Observable
final class CurrentUserProfileViewModel: ErrorPresenter {

	var pickedPhoto: PickedPhoto?
	var isLoading = false

	func shouldUpdateDisplayName(for user: CurrentUserModel) -> Bool {
		Auth
			.auth().currentUser?.displayName != user.name.trimmed && user.name.isWhitespace == false
	}
	func shouldUpdateProfile(for user: CurrentUserModel) -> Bool {
		shouldUpdateDisplayName(for: user) || shouldUpdateProfileImage()
	}
	func shouldUpdateProfileImage() -> Bool {
		pickedPhoto != nil
	}
	func isProfileComplete(for user: CurrentUserModel) -> Bool {
		user.name.isWhitespace == false
	}
	@concurrent
	func applyUpdates(for snapshot: CurrentUserModel) async throws {
		guard let currentUser = Auth.auth().currentUser else {
			return
		}
		let request = currentUser.createProfileChangeRequest()
		request.displayName = snapshot.name.trimmed
		try await request.commitChanges()
	}

	@concurrent
	func uploadImage(image: UIImage) async throws -> String {
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
		request.photoURL = URL(string: url)
		try await request.commitChanges()
		return url
	}

	func setLoading(_ isLoading: Bool) {
		self.isLoading = isLoading
	}
}
