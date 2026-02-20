import Core
import Database
import ImageLoader
import MediaPicker
import SwiftUI
import XUI

public struct UserProfileView: View {
	@LazyState private var viewModel: UserProfileViewModel
	@FocusState private var isFocused: Bool

	public init(viewModel: UserProfileViewModel) {
		_viewModel = .init(wrappedValue: viewModel)
	}

	public var body: some View {
		Form {
			Section {
				VStack {
					PhotoPickerButton(
						pickedPhoto: pickedPhoto,
						size: 200,
						clipShape: Circle()
					) {
						ResizableImage(viewModel.state.currentUser.photoURL)
					}
				}
				.flexible(.horizontal)
			} footer: {
				Text(viewModel.state.currentUser.photoURL)
					.textSelection(.enabled)
			}
			.listRowBackground(Color.clear)

			Section {
				LabeledContent {
					RenameButton()
						.labelStyle(.iconOnly)
						.renameAction($isFocused)
				} label: {
					TextField("Enter Display Name", text: userName)
						.focused($isFocused)
						.textContentType(.name)
						.textInputAutocapitalization(.words)
				}

				Text("Phone").badge(viewModel.state.currentUser.mobile)

				if let privateKey = GroupStorage.shared
					.string(for: .security(.privateKey(id: viewModel.state.currentUser.uid)))
				{
					Text(privateKey)
				}

				if let publicKey = GroupStorage.shared
					.string(for: .security(.publicKey(id: viewModel.state.currentUser.uid)))
				{
					Text(publicKey)
				}
			}

			Section {
				Button("Sign Out") {
					Task { await viewModel.send(.signOut) }
				}
				.buttonStyle(.roundedButtonStyle)

				Button("Remove Display Name") {
					Task { await viewModel.send(.removeDisplayName) }
				}
				.buttonStyle(.roundedButtonStyle)

				if viewModel.hasChanges {
					Button("Reset") {
						Task { await viewModel.send(.resetChanges) }
					}
					.buttonStyle(.roundedButtonStyle)
				}
			}
			.listRowSeparator(.hidden)
		}
		.navigationTitle("Profile")
		.refreshable {
			await viewModel.send(.refreshRemote)
		}
		.scrollDismissesKeyboard(.immediately)
		.toolbar {
			if viewModel.hasChanges {
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						setFocus(false)
						Task { await viewModel.send(.saveChanges) }
					} label: {
						if viewModel.state.isLoading {
							ProgressView().controlSize(.mini)
						} else {
							Text("Save")
						}
					}
				}
			}
		}
		.task {
			await viewModel.send(.appear)
		}
	}

	private var userName: Binding<String> {
		Binding(
			get: { viewModel.state.currentUser.name },
			set: { newValue in
				Task { await viewModel.send(.editName(newValue)) }
			}
		)
	}

	private var pickedPhoto: Binding<PickedPhoto?> {
		Binding(
			get: { viewModel.pickedPhoto },
			set: { newValue in
				viewModel.pickedPhoto = newValue
			}
		)
	}

	public func setFocus(_ isFocused: Bool) {
		self.isFocused = isFocused
	}
}
