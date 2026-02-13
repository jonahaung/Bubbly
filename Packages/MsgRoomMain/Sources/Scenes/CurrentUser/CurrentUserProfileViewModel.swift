import Core
import Database
import FirebaseAuth
import MediaPicker
import Services
import UIKit

@MainActor
@Observable
public final class CurrentUserProfileViewModel: ErrorPresenter {
	public var pickedPhoto: PickedPhoto?
	public var isLoading = false

	public init() {}
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
	public func removeDisplayName() async throws {
		guard let user = Auth.auth().currentUser else {
			return
		}
		let request = user.createProfileChangeRequest()
		request.displayName = nil
		try await request.commitChanges()
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
}
