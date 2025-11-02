//
//  SettingsScene.swift
//  Bubbly
//
//  Created by Aung Ko Min on 16/5/25.
//

import SwiftUI
import FirebaseAuth
import XUI
import FirePhoneOTP
import FirebaseMessaging
import Services
import MsgRoomMain
import Database
import SwiftData
import Core
import ImageLoader

struct SettingsScene: View {

	@Environment(AuthService.self) private var authService
	@Environment(\.currentUser) private var currentUser

	@AppStorage(
		StorageKeys.layout(.chatMsgSpacing).value,
		store: GroupAppStorage.shared.store
	) var chatCellVerticalSpacing: Int = Settings.Layout.chatMsgSpacing
	@AppStorage(
		StorageKeys.limit(.paginationPageSize).value,
		store: GroupAppStorage.shared.store
	) var paginationPageSize: Int = 50

	@AppStorage(
		StorageKeys.limit(.minutesForChatMsgGrouping).value,
		store: GroupAppStorage.shared.store
	) var minutesForChatMsgGrouping: Int = 15
	@AppStorage("askChatGPT") private var askChatGPT: Bool = false

	var body: some View {
		Form {
			profilePhotoSection
			Section(header: Text("Sign Out")) {
				Button {
					Router.shared.push(.currentUserDetails)
				} label: {
					Text("Profile").badge(currentUser.name)
				}
				AsyncButton {
					try Auth.auth().signOut()
				} label: {
					Text("Sign Out")
				}
			}
			Section {
				Stepper.init(value: $chatCellVerticalSpacing) {
					Text(
						"Chat Cell Vertical Spacing: \(chatCellVerticalSpacing)"
					)
				}

				Stepper.init(
					value: $paginationPageSize,
					in: 20...100,
					step: 10
				) {
					Text("Pagination Page Size: \(paginationPageSize)")
				}
				Stepper.init(
					value: $minutesForChatMsgGrouping,
					in: 2...180,
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

			} footer: {
				AsyncButton {
					try Folder.documents?.delete()
				} label: {
					Text("Clean Up File System")
				} onError: { error in
					Log(error)
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
							msgs.forEach { each in
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
							msgs.forEach { each in
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
						let descriptor = FetchDescriptor<PGroup>()
						do {
							let msgs = try context.fetch(descriptor)
							msgs.forEach { each in
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
						PhotoViewer(
							.init(url: currentUser.photoURL, type: .photo),
							title: currentUser.name
						)
					}
			}
			.flexible(.horizontal)
		}
		.listRowInsets(.init())
		.listRowBackground(Color.clear.hidden())
	}
}
