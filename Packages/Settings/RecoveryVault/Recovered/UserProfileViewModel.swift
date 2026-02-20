import Database
import MediaPicker
import Observation
import Services

@MainActor
@Observable
public final class UserProfileViewModel: ErrorPresenter {
	private(set) var state: UserProfileViewState

	private let observeUserProfile: ObserveUserProfileUseCase
	private let refreshUserProfile: RefreshUserProfileUseCase
	private let editUserProfileName: EditUserProfileNameUseCase
	private let setUserProfilePhoto: SetUserProfilePhotoUseCase
	private let resetUserProfileChanges: ResetUserProfileChangesUseCase
	private let saveUserProfile: SaveUserProfileUseCase
	private let signOutUserProfile: SignOutUserProfileUseCase
	private let removeDisplayName: RemoveUserProfileDisplayNameUseCase
	private let latestSnapshot: LatestUserProfileSnapshotUseCase

	public init(currentUserRepository: CurrentUserRepositoryProtocol) {
		let manager = UserProfileManager(currentUserRepository: currentUserRepository)
		let repository = UserProfileRepositoryImpl(manager: manager)
		observeUserProfile = ObserveUserProfileUseCaseImpl(repository: repository)
		refreshUserProfile = RefreshUserProfileUseCaseImpl(repository: repository)
		editUserProfileName = EditUserProfileNameUseCaseImpl(repository: repository)
		setUserProfilePhoto = SetUserProfilePhotoUseCaseImpl(repository: repository)
		resetUserProfileChanges = ResetUserProfileChangesUseCaseImpl(repository: repository)
		saveUserProfile = SaveUserProfileUseCaseImpl(repository: repository)
		signOutUserProfile = SignOutUserProfileUseCaseImpl(repository: repository)
		removeDisplayName = RemoveUserProfileDisplayNameUseCaseImpl(repository: repository)
		latestSnapshot = LatestUserProfileSnapshotUseCaseImpl(repository: repository)
		state = UserProfileViewState(
			currentUser: .empty,
			originalUser: .empty,
			isLoading: false,
			error: nil,
			shouldDismiss: false,
			hasPickedPhoto: false
		)
		observeManagerChanges()
	}

	var pickedPhoto: PickedPhoto? {
		get { observeUserProfile.repository.manager.pickedPhoto }
		set { Task { await send(.setPickedPhoto(newValue)) } }
	}

	var hasChanges: Bool {
		state.currentUser != state.originalUser || state.hasPickedPhoto
	}

	func send(_ intent: UserProfileIntent) async {
		switch intent {
		case .appear:
			await handleAppear()
		case .refreshRemote:
			await handleRefreshRemote()
		case let .editName(value):
			await handleEditName(value)
		case let .setPickedPhoto(value):
			await handleSetPickedPhoto(value)
		case .resetChanges:
			await handleResetChanges()
		case .saveChanges:
			await handleSaveChanges()
		case .signOut:
			await handleSignOut()
		case .removeDisplayName:
			await handleRemoveDisplayName()
		}
	}

	private func handleAppear() async {
		let snapshot = await observeUserProfile.execute()
		state = makeState(snapshot: snapshot, isLoading: false, error: nil)
	}

	private func handleRefreshRemote() async {
		state = updatedState(isLoading: true, error: nil)
		do {
			let snapshot = try await refreshUserProfile.execute()
			state = makeState(snapshot: snapshot, isLoading: false, error: nil)
		} catch {
			state = updatedState(isLoading: false, error: error.localizedDescription)
			await showError(error)
		}
	}

	private func handleEditName(_ value: String) async {
		let snapshot = await editUserProfileName.execute(value)
		state = makeState(snapshot: snapshot, isLoading: false, error: state.error)
	}

	private func handleSetPickedPhoto(_ value: PickedPhoto?) async {
		let snapshot = await setUserProfilePhoto.execute(value)
		state = makeState(snapshot: snapshot, isLoading: false, error: state.error)
	}

	private func handleResetChanges() async {
		let snapshot = await resetUserProfileChanges.execute()
		state = makeState(snapshot: snapshot, isLoading: false, error: nil)
	}

	private func handleSaveChanges() async {
		state = updatedState(isLoading: true, error: nil)
		do {
			let snapshot = try await saveUserProfile.execute()
			state = makeState(snapshot: snapshot, isLoading: false, error: nil)
		} catch {
			state = updatedState(isLoading: false, error: error.localizedDescription)
			await showError(error)
		}
	}

	private func handleSignOut() async {
		do {
			try await signOutUserProfile.execute()
		} catch {
			await showError(error)
		}
	}

	private func handleRemoveDisplayName() async {
		state = updatedState(isLoading: true, error: nil)
		do {
			let snapshot = try await removeDisplayName.execute()
			state = makeState(snapshot: snapshot, isLoading: false, error: nil)
		} catch {
			state = updatedState(isLoading: false, error: error.localizedDescription)
			await showError(error)
		}
	}

	private func observeManagerChanges() {
		withObservationTracking {
			_ = observeUserProfile.repository.manager.currentUser
			_ = observeUserProfile.repository.manager.currentUserRepository.model
			_ = observeUserProfile.repository.manager.pickedPhoto
		} onChange: { [weak self] in
			guard let self else {
				return
			}
			Task { @MainActor in
				let snapshot = await latestSnapshot.execute()
				state = makeState(
					snapshot: snapshot,
					isLoading: state.isLoading,
					error: state.error,
					shouldDismiss: state.shouldDismiss
				)
				observeManagerChanges()
			}
		}
	}

	private func makeState(snapshot: UserProfileSnapshot,
	                       isLoading: Bool,
	                       error: String?,
	                       shouldDismiss: Bool = false) -> UserProfileViewState
	{
		UserProfileViewState(
			currentUser: snapshot.currentUser,
			originalUser: snapshot.originalUser,
			isLoading: isLoading,
			error: error,
			shouldDismiss: shouldDismiss,
			hasPickedPhoto: snapshot.hasPickedPhoto
		)
	}

	private func updatedState(isLoading: Bool,
	                          error: String?,
	                          shouldDismiss: Bool? = nil) -> UserProfileViewState
	{
		UserProfileViewState(
			currentUser: state.currentUser,
			originalUser: state.originalUser,
			isLoading: isLoading,
			error: error,
			shouldDismiss: shouldDismiss ?? state.shouldDismiss,
			hasPickedPhoto: state.hasPickedPhoto
		)
	}
}
