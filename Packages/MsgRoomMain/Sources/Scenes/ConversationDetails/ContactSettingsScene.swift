//
//  ContactSettingsScene.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 23/10/24.
//

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
	@Environment(\.currentUser) private var currentUser

	public init(
		_ contact: Contact
	) {
		self.contact = contact
		self.properties = .init(uid: "")
	}

	public var body: some View {
		List {
			Section {
				FormCell("Name", contact.name)
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
					Stepper("Cornor Radius - \(properties.theme.bubbleCornorRadius.int)", value: bubbleCornorRadius)
				}
			}
			Section {
				AsyncButton {
					try await ConversationRepo.deleteMessages(conID: Conversation(.contact(contact), properties: properties).uid)
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
					try await Store.shared.contactStore
						.updateAndSave(uid: newValue.uid) { model in
							model.merge(from: newValue)
						}
					try await Task.sleep(seconds: 0.5)
					await MainActor.run {
						isSaving = false
					}
				} catch {
					Log(error)
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
					try await Store.shared.conversationPropertiesStore
						.updateAndSave(uid: newValue.uid) { model in
							model.theme = newValue.theme
						}
					try await Task.sleep(seconds: 0.5)
					await MainActor.run {
						isSaving = false
					}
				} catch {
					Log(error)
					await MainActor.run {
						isSaving = false
					}
				}
			}
		}
		.task {
			if let value = try? await ConversationPropertiesRepo.getOrCreate(
				for: ConversationIDGenerator.generate(currentUser.uid, contact.uid)
			) {
				properties = value
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

	private var bubbleCornorRadius: Binding<CGFloat> {
		.init {
			properties.theme.bubbleCornorRadius
		} set: { newValue in
			properties.theme.bubbleCornorRadius = newValue
		}
	}
}
