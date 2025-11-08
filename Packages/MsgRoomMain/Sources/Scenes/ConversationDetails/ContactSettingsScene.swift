//
//  ConversationDetailsScene.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 23/10/24.
//

import SwiftUI
import Core
import XUI
import Services
import Database

public struct ContactSettingsScene: View {

	@State private var contact: Contact
	@State private var updatingModelValueTask: Task<Void, Never>?
	@State private var isSaving: Bool = false

	public init(
		_ contact: Contact
	) {
		self.contact = contact
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
					Stepper("Cornor Radius - \(contact.theme?.bubbleCornorRadius.int ?? 0)", value: bubbleCornorRadius)
				}
			}
			Section {
				AsyncButton {
					try await ConversationRepo.deleteMessages(conID: AnyConversation(.contact(contact)).uid)
				} label: {
					Text("Delete Messages")
				}
			}
			Section {

			} footer: {
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
							model.update(with: newValue)
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
	}

	private var bubbleColor: Binding<BubbleColor> {
		.init {
			(contact.theme ?? .default).bubbleColor
		} set: { newValue in
			var theme = contact.theme ?? .default
			theme.bubbleColor = newValue
			contact.theme = theme
		}

	}
	private var background: Binding<ChatBackground> {
		.init {
			(contact.theme ?? .default).background
		} set: { newValue in
			var theme = contact.theme ?? .default
			theme.background = newValue
			contact.theme = theme
		}
	}
	private var bubbleCornorRadius: Binding<CGFloat> {
		.init {
			(contact.theme ?? .default).bubbleCornorRadius
		} set: { newValue in
			var theme = contact.theme ?? .default
			theme.bubbleCornorRadius = newValue
			contact.theme = theme
		}
	}
}
