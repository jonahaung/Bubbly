//
//  CreateGroupScene.swift
//  Bubbly
//
//  Created by Aung Ko Min on 28/4/25.
//

import SwiftUI
import XUI
import Database
import Services
import MediaPicker
import ImageLoader

public struct CreateGroupScene: View {

	@Environment(ContactStore.self) private var contactStore
	@State private var viewModel = CreateGroupViewModel()
	@Environment(\.dismiss) private var dismiss
	@FocusState private var isFocused: Bool

	public init() {}

	public
	var body: some View {
		Form {
			Section {
				HStack(spacing: 20) {
					PhotoPickerButton(
						pickedPhoto: $viewModel.pickedPhoto,
						clipShape: Circle()
					) {
						ResizableImage(viewModel.uploadedURL?.absoluteString)
					}
					TextField("Group Name", text: $viewModel.groupName)
						.textInputAutocapitalization(.words)
						.autocorrectionDisabled()
						.textContentType(.organizationName)
						.autocorrectionDisabled()
						.focused($isFocused)
				}
				.padding(.vertical, 4)
			}
			.buttonStyle(.borderless)

			Section {
				ForEach(viewModel.selection, id: \.uid) { contact in
					HStack(spacing: 20) {
						ProfilePhoto(contact)
							.frame(square: 30)
							.padding(.vertical, 2)
						Text(contact.name)
							.frame(maxWidth: .infinity, alignment: .leading)
						Button {
							if let index = viewModel.selection.firstIndex(
								where: { $0.uid == contact.uid }
							) {
								viewModel.selection.remove(at: index)
							}
						} label: {
							SystemImage(.minusCircleFill, 20)
								.symbolRenderingMode(.multicolor)
						}
					}
					.buttonStyle(.borderless)
				}
				Label(
					"Add Members",
					systemSymbol: .plusCircleFill
				)
				.presentSheet {
					ContactPickerScene(selection: $viewModel.selection)
				}
			} header: {
				Text("Members")
			}
		}
		.scrollDismissesKeyboard(.immediately)
		.animation(.bouncy, value: viewModel.selection)
		.ignoresSafeArea(.keyboard)
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				AsyncButton {
					setFocus(false)
					try await Task.sleep(seconds: 1)
					try await viewModel.createGroup()
					try await contactStore.syncGroups()
					dismiss()
				} label: { _ in
					if viewModel.isLoading {
						ProgressView().controlSize(.mini)
					} else {
						Text("Create")
					}
				}
				.disabled(
					!viewModel.canCreateGroup
				)
			}
			ToolbarItem(placement: .topBarLeading) {
				Button {
					dismiss()
				} label: {
					Text("Cancel")
				}
			}
		}
		.onAppear {
			if viewModel.groupName.isWhitespace {
				isFocused = true
			} else {
				isFocused = false
			}
		}
	}

	@MainActor private func setFocus(_ isFoucsed: Bool) {
		self.isFocused = isFoucsed
	}
}
