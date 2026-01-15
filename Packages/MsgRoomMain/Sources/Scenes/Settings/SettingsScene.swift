//
//  SettingsScene.swift
//  Bubbly
//
//  Created by Aung Ko Min on 16/5/25.
//

import Core
import Database
import FirebaseAuth
import FirebaseMessaging
import FirePhoneOTP
import ImageLoader
import Services
import SwiftData
import SwiftUI
import XUI

struct SettingsScene: View {

	@Environment(AppLauncher.self) private var appLauncher
    @Environment(\.currentUser) private var currentUser

	@AppStorage("fontName") private var fontName: String?

    @AppStorage(
        GroupStorageKey.layout(.chatMsgSpacing).value,
        store: GroupStorage.shared.store
    ) var chatCellVerticalSpacing: Int = Settings.Layout.chatMsgSpacing
    @AppStorage(
        GroupStorageKey.limit(.paginationPageSize).value,
        store: GroupStorage.shared.store
    ) var paginationPageSize: Int = 50

    @AppStorage(
        GroupStorageKey.limit(.minutesForChatMsgGrouping).value,
        store: GroupStorage.shared.store
    ) var minutesForChatMsgGrouping: Int = 15
    @AppStorage("askChatGPT") private var askChatGPT: Bool = false

    var body: some View {
        Form {
            profilePhotoSection
            Section(header: Text("Sign Out")) {
				NavigationLink(value: NavPath.currentUserDetails) {
					FormCell("Profile", currentUser.name)
				}
                AsyncButton {
					appLauncher.resetGetStarted()
                } label: {
                    Text("Sign Out")
                }
            }
            Section {
                Stepper(value: $chatCellVerticalSpacing) {
                    Text(
                        "Chat Cell Vertical Spacing: \(chatCellVerticalSpacing)"
                    )
                }

                Stepper(
                    value: $paginationPageSize,
                    in: 20 ... 100,
                    step: 10
                ) {
                    Text("Pagination Page Size: \(paginationPageSize)")
                }
                Stepper(
                    value: $minutesForChatMsgGrouping,
                    in: 2 ... 180,
                    step: 2
                ) {
                    Text(
                        "Minutes For Chat Msg Grouping: \(minutesForChatMsgGrouping)"
                    )
                }
                FormCell {
                    Text("File System")
                } right: {
                    if let path = Folder.documents?.path {
                        Text(path)
                    }
                }._tapToPush {
                    if let documents = Folder.documents {
                        Text(documents.description)
                    }
                }
				FormCell {
					Text("Font")
				} right: {
					Text(fontName ?? UIFont.systemFontFamilyName)
						.presentSheet {
							FontPicker(selection: $fontName)
						}
				}

            } footer: {
                AsyncButton {
                    try Folder.documents?.delete()
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
                Toggle(isOn: $askChatGPT) {
                    Text("Ask Chat GPT")
                }
                Text(currentUser.preetyPrinted)
            }
            Section {
                AsyncButton { @MainActor in
                    let context = Store.shared.modelContainer.mainContext
                    try context.transaction {
                        let descriptor = FetchDescriptor<PMsg>()
                        do {
                            let msgs = try context.fetch(descriptor)
                            for each in msgs {
                                context.delete(each)
                            }
                        } catch {
                            Log(error)
                        }
                    }
                } label: {
                    Text("Delete Messages")
                }
                AsyncButton { @MainActor in
                    let context = Store.shared.modelContainer.mainContext
                    try context.transaction {
                        let descriptor = FetchDescriptor<PContact>()
                        do {
                            let msgs = try context.fetch(descriptor)
                            for each in msgs {
                                context.delete(each)
                            }
                        } catch {
                            Log(error)
                        }
                    }
                } label: {
                    Text("Delete Contacts")
                }
                AsyncButton { @MainActor in
                    let context = Store.shared.modelContainer.mainContext
                    try context.transaction {
						let descriptor = FetchDescriptor<PConversationProperties>()
                        do {
                            let msgs = try context.fetch(descriptor)
                            for each in msgs {
                                context.delete(each)
                            }
                        } catch {
                            Log(error)
                        }
                    }
                } label: {
                    Text("Delete Conversations")
                }
            }
        }
        .formStyle(.grouped)
    }

    private var profilePhotoSection: some View {
        Section {
            VStack {
                ResizableImage(currentUser.photoURL, processors: [.circle()])
                    .frame(square: 200)
                    .sheetWithZoomTransition {
						PhotoGalleryCell(
							currentUser
                        )
                    }
            }
            .flexible(.horizontal)
        }
        .listRowInsets(.init())
        .listRowBackground(Color.clear.hidden())
    }
}

extension CurrentUserModel: @retroactive PhotoGalleryItem {
	public var galleryURL: URL? {
		.init(string: photoURL)
	}
	public var galleryTitle: String? {
		name
	}
}
