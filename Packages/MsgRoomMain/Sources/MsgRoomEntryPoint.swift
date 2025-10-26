//
//  XBadgedModifier.swift
//  Services
//
//  Created by Aung Ko Min on 3/2/25.
//

import SwiftUI
import Database
import Core
import Services
import XUI

private struct MsgRoomEntryPointModifier: ViewModifier, ErrorPresenter {
	private let currentUser: CurrentUser
	private let contactStore = ContactStore.shared

	init(user: Contact) {
		currentUser = .init(user)
	}

	func body(content: Content) -> some View {
		content
			.environment(currentUser)
			.environment(contactStore)
			.environment(\.sendChatRoomAction) { data in
				Task.detached {
					do {
						let conversation = try await ConversationRepo.getOrCreate(
							for: data.conID, refetch: false)
						try await Socket.shared
							.send(data, conversation: conversation)
					} catch {
						Log(error)
					}
				}
			}
			.task {
				try? await currentUser.updateIfNeeded()
				try? await contactStore.syncGroups()
			}
	}
}

public extension View {
	func msgRoomEntryPoint(user: Contact) -> some View {
		ModifiedContent(
			content: self,
			modifier: MsgRoomEntryPointModifier(
				user: user
			)
		)
	}
}
