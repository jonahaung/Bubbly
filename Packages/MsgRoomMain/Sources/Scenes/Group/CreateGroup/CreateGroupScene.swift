import Database
import ImageLoader
import MediaPicker
import Services
import SwiftUI
import XUI

public struct CreateGroupScene: View {
	@Environment(ContactsRepository.self) private var contactStore
	@State private var viewModel = CreateGroupViewModel()
	@Environment(\.dismiss) private var dismiss
	@FocusState private var isFocused: Bool
	@Environment(\.currentUser) private var currentUser

	public init() {}

	public var body: some View {
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
					Label {
						LabeledContent(contact.name) {
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
					} icon: {
						ProfilePhoto(contact, size: .mini)
					}
				}
				LabeledContent("Add Members") {
					Image(systemSymbol: .plus)
						.imageScale(.large)
				}
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
			ToolbarItem(placement: .primaryAction) {
				AsyncButton(role: .confirm) {
					setFocus(false)
					try await Task.sleep(seconds: 1)
					try await viewModel.createGroup()
					try await contactStore.syncGroups(currentUser: currentUser)
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
			ToolbarItem(placement: .cancellationAction) {
				Button(role: .cancel) {
					dismiss()
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
		isFocused = isFoucsed
	}
}
