//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import ImageLoader
import Services
import SwiftUI
import XUI

public struct SettingsScene: View {
	
    @State private var viewModel: SettingsSceneViewModel
	@AppStorage("Lazy Scroll View") private var lazyScrollView: Bool = true

    public init(coordinator: AppCoordinator) {
		_viewModel = .init(wrappedValue: .init(coordinator: coordinator))
    }

    public var body: some View {
        let currentUser = viewModel.state.currentUser
        Form {
            profilePhotoSection
            Section(header: Text("Sign Out")) {
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
            Section {
				Toggle.init("Lazy Scroll View", isOn: $lazyScrollView)
                Stepper(value: chatCellVerticalSpacingBinding) {
                    Text("Chat Cell Vertical Spacing: \(viewModel.state.chatCellVerticalSpacing)")
                }

                Stepper(
                    value: paginationPageSizeBinding,
                    in: 50...1000,
                    step: 50
                ) {
                    Text("Pagination Page Size: \(viewModel.state.paginationPageSize)")
                }
                Stepper(
                    value: minutesForChatMsgGroupingBinding,
                    in: 2...180,
                    step: 2
                ) {
                    Text(
                        "Minutes For Chat Msg Grouping: \(viewModel.state.minutesForChatMsgGrouping)"
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
            Section {
                PermissionView(.notification(access: [.alert, .badge, .sound]))
                PermissionView(.contacts)
                PermissionView(.camera)
                PermissionView(.mediaLibrary)
                PermissionView(.photoLibrary)
                PermissionView(.microphone)
            } header: {
                Text("Permissions")
            }
            Section {
                Text(currentUser.preetyPrinted)
            }
            Section {
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
        .buttonStyle(.borderless)
        .buttonSizing(.flexible)
        .formStyle(.grouped)
    }

    private var chatCellVerticalSpacingBinding: Binding<Int> {
        Binding(
            get: { viewModel.state.chatCellVerticalSpacing },
            set: { value in
                Task { @MainActor in
                    await viewModel.send(.setChatCellVerticalSpacing(value))
                }
            }
        )
    }

    private var paginationPageSizeBinding: Binding<Int> {
        Binding(
            get: { viewModel.state.paginationPageSize },
            set: { value in
                Task { @MainActor in
                    await viewModel.send(.setPaginationPageSize(value))
                }
            }
        )
    }

    private var minutesForChatMsgGroupingBinding: Binding<Int> {
        Binding(
            get: { viewModel.state.minutesForChatMsgGrouping },
            set: { value in
                Task { @MainActor in
                    await viewModel.send(.setMinutesForChatMsgGrouping(value))
                }
            }
        )
    }

    private var profilePhotoSection: some View {
        Section {
            let currentUser = viewModel.state.currentUser
            ZStack(alignment: .bottomTrailing) {
                ResizableImage(
                    currentUser.photoURL,
                    processors: [.circle(border: .init(color: .systemGroupedBackground, width: 5))]
                )
                .frame(square: 170)
                .background(.background, in: .circle)
                .padding()
                .sheetWithZoomTransition {
                    PhotoGalleryCell(currentUser)
                }
            }
            .frame(height: 300)
            .frame(maxWidth: .infinity)
            .background(MeshGradient(
                width: 2,
                height: 2,
                points: [
                    [-0.4, -0.4], [1, 0],
                    [0, 1], [1.0, 1.0]
                ],
                colors: [
                    .purple, .mint,
                    .orange, .blue
                ]
            ), in: ProfileBackgroundShape())
        }
        .listRowInsets(.init())
        .listSectionMargins(.init(), 0)
        .listRowBackground(Color.clear.hidden())
    }
}
