//
//  ConversationProfileScene.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 24/8/25.
//

import SwiftUI
import Database
import Services
import XUI
import MediaPicker
import ImageLoader

public struct GroupConversationSettingsScene: View {

	@State private var viewModel: GroupDetailsViewModel
	@Environment(ContactStore.self) private var contactStore
	@Environment(CurrentUser.self) private var currentUser
	@FocusState private var isFocused: Bool

	public init(_ group: Database.Group) {
		_viewModel = .init(wrappedValue: .init(group: group))
	}

	public var body: some View {
		Form {
			Section {
				FormCell {
					TextField("Group Name", text: $viewModel.group.name)
						.textInputAutocapitalization(.words)
						.focused($isFocused)
				} right: {
					Button {
						isFocused = true
					} label: {
						SystemImage(.squareAndPencil)
					}
					.buttonStyle(.borderless)
				}
			} header: {
				VStack {
					PhotoPickerButton(
						pickedPhoto: $viewModel.pickedPhoto,
						size: 150,
						clipShape: Circle()
					) {
						ResizableImage(viewModel.group.photoURL)
					}
					.padding()
				}
				.flexible(.horizontal)
			}

			Section {
				XNavPickerBar<BubbleColor>(
					"Bubble Color",
					BubbleColor.allCases,
					$viewModel.group.theme.bubbleColor
				)
				XNavPickerBar<ChatBackground>(
					"Chat Background",
					ChatBackground.allCases,
					$viewModel.group.theme.background
				)
			}
			Section {
				AsyncButton {
					try await ConversationRepo.deleteMessages(conID: viewModel.group.uid)
				} label: {
					Text("Delete Messages")
				} onFinish: {
					Task { @MainActor in
						Router.shared.currentNavRouter?.navPath.removeAll()
					}
				}
			}
			Section {
				FormCell("Created", viewModel.group.createdDate.date.formatted(date: .abbreviated, time: .shortened))
				if let admin = viewModel.group.createdBy == currentUserId ? currentUser.user : contactStore.contact(for: viewModel.group.createdBy) {
					FormCell("Admin", admin.name)
				}
			}
			Section {
				ForEach(viewModel.contacts) { contact in
					ContactCell(contact)
				}
			} header: {
				Text("Members")
			} footer: {
				Label("Add Member...", systemImage: "plus.circle.fill")
					.presentFullScreen {
						ContactPickerScene(selection: $viewModel.contacts)
					}
			}

			Section {
				Text(viewModel.group.preetyPrinted)
					.font(.system(.caption2, design: .monospaced, weight: .light))
			}
		}
		.navigationTitle("Settings")
		.toolbar {
			if viewModel.hasChanges {
				ToolbarItem(placement: .topBarLeading) {
					Button {
						viewModel.reset()
					} label: {
						Text("Reset")
					}
				}
			}
			ToolbarItem(placement: .topBarTrailing) {
				AsyncButton {
					if let image = await viewModel.pickedPhoto?.uiImage {
						let url = try await viewModel.uploadImage(image: image)
						await MainActor.run {
							viewModel.group.photoURL = url
//							viewModel.pickedPhoto = nil
						}
					}
					try await viewModel.applyUpdate()
				} label: {
					if viewModel.isLoading {
						ProgressView().controlSize(.mini)
					} else {
						Text("Save")
					}
				} onFinish: {
					Task { @MainActor in
						viewModel.originalGroup = viewModel.group
					}
				} onError: { error in
					Task {
						await viewModel.setLoading(false)
						await viewModel.showError(error)
					}
				}
				.disabled(!viewModel.hasChanges)
			}
		}
		.scrollDismissesKeyboard(.immediately)
		.navigationBarBackButtonHidden(viewModel.hasChanges)
	}
}
