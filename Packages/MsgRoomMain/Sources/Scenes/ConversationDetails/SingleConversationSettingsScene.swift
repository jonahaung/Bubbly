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

public struct SingleConversationSettingsScene: View {

	@State private var conversation: ConversationSnapshot
	@State private var updatingModelValueTask: Task<Void, Never>?
	@State private var isSaving: Bool = false

	public init(
		_ conversation: ConversationSnapshot
	) {
		self.conversation = conversation
	}

	public var body: some View {
		List {
			Section {
				FormCell("Name", conversation.name)
			}
			Section {
				Section {
					XNavPickerBar<BubbleColor>(
						"Bubble Color",
						BubbleColor.allCases,
						$conversation.theme.bubbleColor
					)
					XNavPickerBar<ChatBackground>(
						"Chat Background",
						ChatBackground.allCases,
						$conversation.theme.background
					)

					Stepper("Cornor Radius - \(conversation.theme.bubbleCornorRadius.int)", value: $conversation.theme.bubbleCornorRadius)
				}
			}
			Section {
				AsyncButton {
					try await ConversationRepo.deleteMessages(conID: conversation.uid)
				} label: {
					Text("Delete Messages")
				}
			}
			Section {

			} footer: {
				Text(conversation.preetyPrinted)
					.textSelection(.enabled)
			}
		}
		.navigationTitle("Settings")
		.navigationBarBackButtonHidden(isSaving)
		.toolbar {
			if isSaving {
				ToolbarItem(placement: .topBarTrailing) {
					ProgressView().controlSize(.mini)
				}
			}
		}
		.onChange(of: conversation) { oldValue, newValue in
			isSaving = true
			Task.detached {
				do {
					try await Store.shared.conversationStore
						.updateAndSave(uid: newValue.uid) { model in
							model.update(with: newValue)
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
}
