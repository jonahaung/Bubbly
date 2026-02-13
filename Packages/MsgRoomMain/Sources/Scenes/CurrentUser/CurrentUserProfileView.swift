import Core
import Crypto
import Database
import FirebaseAuth
import ImageLoader
import MediaPicker
import Services
import SwiftUI
import XUI

public struct CurrentUserProfileView: View {
	//	@Environment(AuthService.self) private var authService
	@State private var currentUser = CurrentUserModel.empty
	@Environment(\.currentUser) private var originalCurrentUser
	@State private var viewModel = CurrentUserProfileViewModel()
	@FocusState private var isFocused: Bool

	public init() {}

	public var body: some View {
		Form {
			Section {
				VStack {
					PhotoPickerButton(
						pickedPhoto: $viewModel.pickedPhoto,
						size: 200,
						clipShape: Circle()
					) {
						ResizableImage(currentUser.photoURL)
					}
				}
				.flexible(.horizontal)
			} footer: {
				Text(currentUser.photoURL)
					.textSelection(.enabled)
			}
			.listRowBackground(Color.clear)

			Section {
				LabeledContent {
					RenameButton()
						.labelStyle(.iconOnly)
						.renameAction($isFocused)
				} label: {
					TextField("Enter Display Name", text: $currentUser.name)
						.focused($isFocused)
						.textContentType(.name)
						.textInputAutocapitalization(.words)
				}

				Text("Phone").badge(currentUser.mobile)

				if let privateKey = GroupStorage.shared
					.string(for: .security(.privateKey(id: currentUser.uid)))
				{
					Text(privateKey)
				}

				if let publicKey = GroupStorage.shared
					.string(for: .security(.publicKey(id: currentUser.uid)))
				{
					Text(publicKey)
				}
			}

			Section {
				AsyncButton {
					try Auth.auth().signOut()
				} label: {
					Text("Sign Out")
				}
				.buttonStyle(.roundedButtonStyle)

				AsyncButton {
					try await viewModel.removeDisplayName()
				} label: {
					Text("Remove Display Name")
				}
				.buttonStyle(.roundedButtonStyle)

				if hasChanges {
					Button("Reset") {
						viewModel.pickedPhoto = nil
						currentUser = originalCurrentUser
					}
					.buttonStyle(.roundedButtonStyle)
				}
			}
			.listRowSeparator(.hidden)
		}
		.navigationTitle("Profile")
		.refreshable {
			try? await Task.sleep(seconds: 1)
			if let remote: CurrentUserModel = try? await FirestoreRepo.getModel(
				for: currentUser.uid,
				collection: .users,
				field: .uid
			) {
				currentUser = remote
			}
		}
		.scrollDismissesKeyboard(.immediately)
		.toolbar {
			if hasChanges {
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						setFocus(false)
						viewModel.setLoading(true)
						Task.detached(priority: .utility) {
							do {
								try await saveProfile()
							} catch {
								await viewModel.showError(error)
							}
						}
					} label: {
						if viewModel.isLoading {
							ProgressView().controlSize(.mini)
						} else {
							Text("Save")
						}
					}
				}
			}
		}
		.task {
			currentUser = originalCurrentUser
		}
	}

	private var hasChanges: Bool {
		currentUser != originalCurrentUser
	}

	private func saveProfile() async throws {
		if let image = viewModel.pickedPhoto?.uiImage {
			let url = try await viewModel.uploadImage(image: image)
			currentUser.photoURL = url.absoluteString
			viewModel.pickedPhoto = nil
		}
		try await viewModel.applyUpdates(for: currentUser)
		CurrentUser.reload()
	}

	public func setFocus(_ isFocused: Bool) {
		self.isFocused = isFocused
	}
}
