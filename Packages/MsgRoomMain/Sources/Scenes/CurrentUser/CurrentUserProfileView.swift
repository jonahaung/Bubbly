//
//  CurrentUserProfileView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 24/5/25.
//

import SwiftUI
import Services
import Database
import XUI
import Core
import MediaPicker
import FirebaseAuth
import Crypto
import ImageLoader

public struct CurrentUserProfileView: View {

	@Environment(AuthService.self) private var authService
	@Environment(CurrentUser.self) private var currentUser
	@Environment(\.dismiss) private var dismiss
	@State private var viewModel = CurrentUserProfileViewModel()
	@FocusState private var isFocused: Bool

	public init() {}

	public var body: some View {
		Form {
			profilePhotoSection
			profileSection
			signOutSection
			resetSection
		}
		.buttonStyle(.borderless)
		.navigationTitle("Profile")
		.scrollDismissesKeyboard(.immediately)
		.toolbar { toolbarContent }
	}

	private var user: Binding<ContactSnapshot> {
		Binding(
			get: { currentUser.user },
			set: { currentUser.user = $0 }
		)
	}

	private var profilePhotoSection: some View {
		Section {
			VStack {
				PhotoPickerButton(
					pickedPhoto: $viewModel.pickedPhoto,
					size: 200,
					clipShape: Circle()
				) {
					ResizableImage(currentUser.user.photoURL)
				}
			}
			.flexible(.horizontal)
		} footer: {
			Text(currentUser.user.photoURL)
				.textSelection(.enabled)
		}
		.listRowBackground(Color.clear)
		.task {
			print(currentUser.user.photoURL)
		}
	}
	private var profileSection: some View {
		Section {
			TextField("Enter Display Name", text: user.name)
				.focused($isFocused)
				.textContentType(.name)
				.textInputAutocapitalization(.words)

			Text("Phone").badge(currentUser.user.mobile)

			if let privateKey = GroupAppStorage.shared.string(for: .security(.privateKey(id: currentUser.user.uid))) {
				Text(privateKey)
			}

			if let publicKey = GroupAppStorage.shared.string(for: .security(.publicKey(id: currentUser.user.uid))) {
				Text(publicKey)
			}
		}
	}

	private var signOutSection: some View {
		Section {
			AsyncButton {
				try Auth.auth().signOut()
			} label: {
				Text("Sign Out")
					.frame(maxWidth: .infinity, alignment: .center)
			}
		}
	}

	private var resetSection: some View {
		Group {
			if viewModel.shouldUpdateProfile(for: currentUser.user) {
				Section {
					Button("Reset") {
						viewModel.pickedPhoto = nil
						currentUser.user.name = Auth.auth().currentUser?.displayName ?? ""
					}
				}
			}
		}
	}

	private var toolbarContent: some ToolbarContent {
		ToolbarItem(placement: .topBarTrailing) {
			if viewModel.isLoading {
				ProgressView().controlSize(.mini)
			} else {
				AsyncButton {
					await saveProfile()
				} label: {
					Text("Save")
				}
				.disabled(!viewModel.shouldUpdateProfile(for: currentUser.user))
			}
		}
	}

	private func saveProfile() async {
		isFocused = false
		viewModel.setLoading(true)
		Task.detached(priority: .background) {
			do {
				if let image = await viewModel.pickedPhoto?.uiImage {
					let url = try await viewModel.uploadImage(image: image)
					await MainActor.run {
						currentUser.user.photoURL = url
						viewModel.pickedPhoto = nil
					}
				}
				try await viewModel.applyUpdates(for: currentUser.user)
				try await currentUser.updateIfNeeded()
				await viewModel.setLoading(false)
				await authService.handleAuthStateChange()
			} catch {
				await viewModel.setLoading(false)
				await viewModel.showError(error)
			}
		}
	}
}
