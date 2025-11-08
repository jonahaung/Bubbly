//
//  ConversationLazyScene.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 29/10/25.
//

import SwiftUI
import XUI
import Database
import Services

public struct ConversationLazyScene: View {

	private let conID: String

	public init(_ conID: String) {
		self.conID = conID
	}
	public var body: some View {
		VStack {
			ProgressView().controlSize(.mini)
		}
		.toolbarVisibility(.hidden, for: .navigationBar, .tabBar)
		.task {
			await loadConversation()
		}
	}
	private func loadConversation() async {
		do {
			let conversation = try await ConversationRepo.getOrCreate(for: conID, refetch: false)
			let data = try await ConversationInitializer.createPrefetchedObject(
				conversation: conversation
			)
			await MainActor.run {
				Router.shared.currentNavRouter?.replace([NavPath.conversation(data)])
			}
		} catch {
			Log(error)
		}
	}
}
