import Core
import Database
import Services
import SwiftUI
import XUI

public struct ContactSettingsScene: View {
	@State private var contact: Contact
	@State private var properties: ConversationProperties
	@State private var updatingModelValueTask: Task<Void, Never>?
	@State private var isSaving: Bool = false

	public init(_ contact: Contact) {
		self.contact = contact
		properties = .init(uid: "")
	}

	public var body: some View {
		List {
			Section {
				LabeledContent("Name") {
					Text(contact.name)
				}
			}
			Section {
				Section {
					XNavPickerBar<BubbleColor>(
						"Bubble Color",
						BubbleColor.allCases,
						bubbleColor
					)
					XNavPickerBar<ChatBackground>(
						"Chat Background",
						ChatBackground.allCases,
						background
					)
					Stepper(
						"Cornor Radius - \(properties.theme.bubbleCornorRadius.int)",
						value: bubbleCornerRadius
					)
				}
			}
			Section {
				AsyncButton {
					try await ConversationRepo.deleteMessages(conID: Conversation(
						.contact(contact),
						properties: properties
					).uid)
				} label: {
					Text("Delete Messages")
				}
			}
			Section {} footer: {
				Text(contact.preetyPrinted)
					.textSelection(.enabled)
			}
		}
		.navigationBarBackButtonHidden(isSaving)
		.toolbar {
			if isSaving {
				ToolbarItem(placement: .topBarTrailing) {
					ProgressView().controlSize(.mini)
				}
			}
		}
		.onChange(of: contact) { _, newValue in
			isSaving = true
			Task.detached {
				do {
					try await Store.shared.contactStore?
						.updateAndSave(uid: newValue.uid) { model in
							model.merge(from: newValue)
						}
					try await Task.sleep(seconds: 0.5)
					await MainActor.run {
						isSaving = false
					}
				} catch {
					log(error)
					await MainActor.run {
						isSaving = false
					}
				}
			}
		}
		.onChange(of: properties) { _, newValue in
			isSaving = true
			Task.detached {
				do {
					try await Store.shared.conversationPropertiesStore?
						.updateAndSave(uid: newValue.uid) { model in
							model.theme = newValue.theme
						}
					try await Task.sleep(seconds: 0.5)
					await MainActor.run {
						isSaving = false
					}
				} catch {
					log(error)
					await MainActor.run {
						isSaving = false
					}
				}
			}
		}
		.task {
			if let currentUserId {
				if let value = try? await ConversationPropertiesRepo.getOrCreate(
					for: ConversationIDGenerator.generate(currentUserId, contact.uid)
				) {
					properties = value
				}
			}
		}
	}

	private var bubbleColor: Binding<BubbleColor> {
		.init {
			properties.theme.bubbleColor
		} set: { newValue in
			properties.theme.bubbleColor = newValue
		}
	}

	private var background: Binding<ChatBackground> {
		.init {
			properties.theme.background
		} set: { newValue in
			properties.theme.background = newValue
		}
	}

	private var bubbleCornerRadius: Binding<CGFloat> {
		.init {
			properties.theme.bubbleCornorRadius
		} set: { newValue in
			properties.theme.bubbleCornorRadius = newValue
		}
	}
}
