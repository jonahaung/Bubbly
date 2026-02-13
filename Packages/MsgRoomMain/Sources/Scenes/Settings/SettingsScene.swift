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
	let currentUserRepository: CurrentUserRepositoryProtocol
	let appLauncher: AppLauncher

	@AppStorage("fontName") private var fontName: String = UIFont.systemFontFamilyName

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
		let currentUser = currentUserRepository.model
		Form {
			profilePhotoSection
			Section(header: Text("Sign Out")) {
				Button {
					Router.shared
						.pushToNav(
							.view(
								id: CurrentUserProfileView.typeName,
								node: RenderNodeView(content: CurrentUserProfileView())
							)
						)
				} label: {
					LabeledContent(currentUser.name, value: currentUser.mobile)
				}

				AsyncButton {
					await appLauncher.resetGetStarted()
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
				Button {
					Router.shared
						.pushToNav(
							.view(
								id: FolderExplorer.typeName,
								node: RenderNodeView(content: FolderExplorer())
							)
						)
				} label: {
					LabeledContent("File System", value: Folder.current.nameExcludingExtension)
				}
				Button {
					Router.shared
						.pushToNav(
							.view(
								id: FontPicker.typeName,
								node: RenderNodeView(content: XUI.FontPicker(selection: $fontName))
							)
						)
				} label: {
					LabeledContent("Font", value: fontName)
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
					guard let context = await Store.shared.modelContainer?.mainContext else {
						return
					}
					try context.transaction {
						let descriptor = FetchDescriptor<PMsg>()
						do {
							let msgs = try context.fetch(descriptor)
							for each in msgs {
								context.delete(each)
							}
						} catch {
							log("\(error)")
						}
					}
				} label: {
					Text("Delete Messages")
				}
				AsyncButton { @MainActor in
					guard let context = await Store.shared.modelContainer?.mainContext else {
						return
					}
					try context.transaction {
						let descriptor = FetchDescriptor<PContact>()
						do {
							let msgs = try context.fetch(descriptor)
							for each in msgs {
								context.delete(each)
							}
						} catch {
							log(error)
						}
					}
				} label: {
					Text("Delete Contacts")
				}
				AsyncButton { @MainActor in
					guard let context = await Store.shared.modelContainer?.mainContext else {
						return
					}
					try context.transaction {
						let descriptor = FetchDescriptor<PConversationProperties>()
						do {
							let msgs = try context.fetch(descriptor)
							for each in msgs {
								context.delete(each)
							}
						} catch {
							log("\(error)")
						}
					}
				} label: {
					Text("Delete Conversations")
				}
				AsyncButton { @MainActor in
					CryptoService.shared.forceReload(for: currentUser.uid)
					CurrentUserRepository.reload()
				} label: {
					Text("Reset Crypto Keys")
				}
			}
		}
		.buttonStyle(.borderless)
		.buttonSizing(.flexible)
		.formStyle(.grouped)
	}

	private var profilePhotoSection: some View {
		Section {
			let currentUser = currentUserRepository.model
			ZStack(alignment: .bottomTrailing) {
				ResizableImage(
					currentUser.photoURL,
					processors: [.circle(border: .init(color: .systemGroupedBackground, width: 5))]
				)
				.frame(square: 170)
				.background(.background, in: .circle)
				.padding()
				.sheetWithZoomTransition {
					PhotoGalleryCell(
						currentUser
					)
				}
			}
			.frame(height: 300)
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
				]
			), in: ProfileBackgroundShape())
		}
		.listRowInsets(.init())
		.listSectionMargins(.init(), 0)
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

struct ProfileBackgroundShape: Shape {
	func path(in rect: CGRect) -> Path {
		let width = rect.width
		let height = rect.height
		return Path { path in
			path.move(to: CGPoint(x: 0, y: 0))
			path.addLine(to: CGPoint(x: 0, y: height / 2))
			path
				.addCurve(
					to: CGPoint(x: width, y: height / 1.7),
					control1: CGPoint(x: width * 1 / 3, y: height),
					control2: CGPoint(x: width * 2 / 3, y: height / 4.5)
				)
			path.addLine(to: CGPoint(x: width, y: 0))
		}
	}
}
