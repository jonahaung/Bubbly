import Core
import Database
import ImageLoader
import MediaPicker
import Services
import SwiftUI
import XUI

public struct GroupConversationSettingsScene: View {
	@State private var viewModel: GroupDetailsViewModel
	@Environment(ContactStore.self) private var contactStore
	@Environment(\.currentUser) private var currentUser
	@FocusState private var isFocused: Bool

	public init(_ group: Database.Group) {
		_viewModel = .init(wrappedValue: .init(group: group))
	}

	public var body: some View {
		Form {
			Section {
				LabeledContent {
					RenameButton()
						.labelStyle(.iconOnly)
						.renameAction($isFocused)
				} label: {
					TextField("Group Name", text: $viewModel.group.name)
						.textInputAutocapitalization(.words)
						.focused($isFocused)
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
					Router.shared.popToRoot()
				} label: {
					Text("Delete Messages")
				}
			}
			Section {
				LabeledContent(
					"Created",
					value: viewModel.group.createdDate.date,
					format: .dateTime
				)
				if let admin: (any ContactRepresentable) = viewModel.group
					.createdBy == currentUserId
					? currentUser
					: contactStore.contact(
						for: viewModel.group.createdBy
					)
				{
					LabeledContent(
						"Admin",
						value: admin.name
					)
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
		.toolbar {
			if viewModel.hasChanges {
				ToolbarItem(placement: .cancellationAction) {
					Button {
						viewModel.reset()
					} label: {
						Text("Reset")
					}
				}
			}
			ToolbarItem(placement: .primaryAction) {
				AsyncButton {
					if let image = viewModel.pickedPhoto?.uiImage {
						let url = try await viewModel.uploadImage(image: image)
						await MainActor.run {
							viewModel.group.photoURL = url.absoluteString
						}
					}
					try await viewModel.applyUpdate()
					Task { @MainActor in
						viewModel.originalGroup = viewModel.group
					}
				} label: {
					if viewModel.isLoading {
						ProgressView().controlSize(.mini)
					} else {
						Text("Save")
					}
				}
				.disabled(!viewModel.hasChanges)
			}
		}
		.scrollDismissesKeyboard(.immediately)
		.navigationBarBackButtonHidden(viewModel.hasChanges)
	}
}
