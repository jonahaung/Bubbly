//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Core
import ImageLoader
import Services
import SwiftUI
import XUI

public struct SettingsScene: View {
	
	public init(coordinator: AppCoordinator) {
		_viewModel = .init(wrappedValue: .init(coordinator: coordinator))
	}

	// MARK: Public
	public var body: some View {
		let currentUser = viewModel.state.currentUser
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                profilePhotoSection
                BackendBaseURLSettingsView()
                ScrollSectionContent("Sign Out") {
                    Button {
                        Task { @MainActor in
                            await viewModel.send(.openUserProfile)
                        }
                    } label: {
                        LabeledContent(currentUser.name, value: currentUser.mobile)
                    }

                    AsyncButton {
                        await viewModel.send(.signOut)
                    } label: {
                        Text("Sign Out")
                    }
                }
                ScrollSectionContent {
                    Toggle("Lazy Scroll View", isOn: $lazyScrollView)
                    Toggle(
                        GroupStorageKey.Conversation.richTextEnabled.localizedName,
                        isOn: $richTextEnabled,
                    )
                    Stepper(value: chatCellVerticalSpacingBinding) {
                        Text("Chat Cell Vertical Spacing: \(viewModel.state.chatCellVerticalSpacing)")
                    }

                    Stepper(
                        value: paginationPageSizeBinding,
                        in: 50 ... 1000,
                        step: 50,
                    ) {
                        Text("Pagination Page Size: \(viewModel.state.paginationPageSize)")
                    }
                    Stepper(
                        value: minutesForChatMsgGroupingBinding,
                        in: 2 ... 180,
                        step: 2,
                    ) {
                        Text(
                            "Minutes For Chat Msg Grouping: \(viewModel.state.minutesForChatMsgGrouping)",
                        )
                    }
                    Button {
                        Task { @MainActor in
                            await viewModel.send(.openFileSystem)
                        }
                    } label: {
                        LabeledContent("File System", value: Folder.current.nameExcludingExtension)
                    }
                    Button {
                        Task { @MainActor in
                            await viewModel.send(.openFontPicker)
                        }
                    } label: {
                        LabeledContent("Font", value: viewModel.state.fontName)
                    }
                } footer: {
                    AsyncButton {
                        await viewModel.send(.cleanUpFileSystem)
                    } label: {
                        Text("Clean Up File System")
                    }
                    .buttonStyle(.roundedButtonStyle)
                }
                ScrollSectionContent {
                    PermissionView(.notification(access: [.alert, .badge, .sound]))
                    PermissionView(.contacts)
                    PermissionView(.camera)
                    PermissionView(.mediaLibrary)
                    PermissionView(.photoLibrary)
                    PermissionView(.microphone)
                } header: {
                    Text("Permissions")
                }
                ScrollSectionContent {
                    Text(currentUser.prettyPrinted)
                }
                ScrollSectionContent {
                    AsyncButton {
                        await viewModel.send(.deleteMessages)
                    } label: {
                        Text("Delete Messages")
                    }
                    AsyncButton {
                        await viewModel.send(.deleteContacts)
                    } label: {
                        Text("Delete Contacts")
                    }
                    AsyncButton {
                        await viewModel.send(.deleteConversations)
                    } label: {
                        Text("Delete Conversations")
                    }
                    AsyncButton {
                        await viewModel.send(.resetCryptoKeys)
                    } label: {
                        Text("Reset Crypto Keys")
                    }
                }
                
            }
        }
        .groupScrollViewStyle()
		.buttonSizing(.flexible)
        .task {
            await viewModel.onAppear()
        }
	}

	
	@AppStorage("Lazy Scroll View") private var lazyScrollView: Bool = true
	
	@AppStorage(GroupStorageKey.conversation(.richTextEnabled).value) private var richTextEnabled: Bool = true

	@State private var viewModel: SettingsSceneViewModel

	private var chatCellVerticalSpacingBinding: Binding<Int> {
		Binding(
			get: { viewModel.state.chatCellVerticalSpacing },
			set: { value in
				Task { @MainActor in
					await viewModel.send(.setChatCellVerticalSpacing(value))
				}
			},
		)
	}

	private var paginationPageSizeBinding: Binding<Int> {
		Binding(
			get: { viewModel.state.paginationPageSize },
			set: { value in
				Task { @MainActor in
					await viewModel.send(.setPaginationPageSize(value))
				}
			},
		)
	}

	private var minutesForChatMsgGroupingBinding: Binding<Int> {
		Binding(
			get: { viewModel.state.minutesForChatMsgGrouping },
			set: { value in
				Task { @MainActor in
					await viewModel.send(.setMinutesForChatMsgGrouping(value))
				}
			},
		)
	}

	private var profilePhotoSection: some View {
        ZStack(alignment: .bottomTrailing) {
            ResizableImage(
                viewModel.state.currentUser.photoURL,
                processors: [.circle(border: .init(color: .systemGroupedBackground, width: 5))],
            )
            .frame(square: 170)
            .background(.background, in: .circle)
            .padding()
            .sheetWithZoomTransition {
                PhotoGalleryCell(viewModel.state.currentUser)
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .background(MeshGradient(
            width: 2,
            height: 2,
            points: [
                [-0.4, -0.4], [1, 0],
                [0, 1], [1.0, 1.0],
            ],
            colors: [
                .purple, .mint,
                .orange, .blue,
            ],
        ), in: ProfileBackgroundShape())
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
	}
}
