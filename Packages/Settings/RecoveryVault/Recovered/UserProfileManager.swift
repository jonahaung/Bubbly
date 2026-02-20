import Database
import MediaPicker
import Observation
import Services

@MainActor
@Observable
final class UserProfileManager {
	private(set) var currentUser: CurrentUserModel
	private var originalUser: CurrentUserModel {
		currentUserRepository.model
	}

	private(set) var pickedPhoto: PickedPhoto?
	let currentUserRepository: CurrentUserRepositoryProtocol

	init(currentUserRepository: CurrentUserRepositoryProtocol) {
		currentUser = currentUserRepository.model
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
