import Core
import Database
import FirebaseAuth
import MediaPicker
import Services
import UIKit

@MainActor
struct UserProfileRepositoryImpl: UserProfileRepository {
	let manager: UserProfileManager

	func observe(initialUser: CurrentUserModel) async -> UserProfileSnapshot {
		manager.bootstrap(initialUser)
		return snapshot()
	}

	func refreshRemote() async throws -> UserProfileSnapshot {
		if let remote: CurrentUserModel = try await FirestoreRepo.getModel(
			for: manager.currentUser.uid,
			collection: .users,
			field: .uid
		) {
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
		let imageUploader = ImageUploadingService()
		let url = try await imageUploader.uploadImage(
			image,
			size: .init(width: 100, height: 100),
			to: .user(uid: authUser.uid)
		)
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
