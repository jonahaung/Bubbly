//
//  AuthUserProfileView.swift
//  Bubbly
//
//  Created by Aung Ko Min on 19/11/25.
//

import Core
import Crypto
import Database
import FirebaseAuth
import ImageLoader
import MediaPicker
import Services
import SwiftUI
import XUI

public struct AuthUserProfileView: View {

	@State private var viewModel: AuthUserProfileViewModel
	@FocusState private var isFocused: Bool

	@Environment(AppLauncher.self) private var appLauncher

	public init(user: User) {
		viewModel = .init(user: user)
	}

	public var body: some View {
		Form {
			Section {
				VStack {
					PhotoPickerButton(
						pickedPhoto: $viewModel.pickedPhoto,
						size: 200,
						clipShape: Circle()
					) {
						ResizableImage(viewModel.editingUser.photoURL)
					}
				}
				.flexible(.horizontal)
			}
			.listRowBackground(Color.clear)

			Section {
				TextField("Enter Display Name", text: $viewModel.editingUser.name)
					.focused($isFocused)
					.textContentType(.name)
					.textInputAutocapitalization(.words)

				Text("Phone").badge(viewModel.editingUser.mobile)
			} footer: {
				if viewModel.isLoading {
					ZStack(alignment: .center) {
						ProgressView().controlSize(.mini)
					}.flexible(.horizontal)
				}
			}
		}
		.safeAreaBar(edge: .bottom) {
			AsyncButton(viewModel.hasChanges ? "Save Changes" : "Continue") {
				if viewModel.hasChanges {
					setFocus(false)
					do {
						try await viewModel.saveProfile()
					} catch {
						await viewModel.showError(error)
					}
				} else {
					do {
						try await viewModel.updateRemoteUser()
						appLauncher.markGetStartedAsDone(user: viewModel.currentUser)
					} catch {
						Log(error)
					}
				}
			}
			.buttonStyle(.roundedButtonStyle)
			.padding(.horizontal)
		}
		.navigationBarBackButtonHidden()
		.scrollDismissesKeyboard(.immediately)
	}

	public func setFocus(_ isFocused: Bool) {
		self.isFocused = isFocused
	}
}
