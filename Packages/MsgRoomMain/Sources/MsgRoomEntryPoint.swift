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
	private let router = Router.shared
	private let contactStore = ContactStore.shared

	init(user: ContactSnapshot) {
		currentUser = .init(user)
	}

	func body(content: Content) -> some View {
		content
			.environment(router)
			.environment(currentUser)
			.environment(contactStore)
			.environment(\.invokeMsgRoomAction) { data in
				Task.detached {
					do {
						let conversation = try await ConversationRepo.getOrCreate(
							for: data.conID, refetch: false)
						await Socket.shared
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
	func msgRoomEntryPoint(user: ContactSnapshot) -> some View {
		ModifiedContent(
			content: self,
			modifier: MsgRoomEntryPointModifier(
				user: user
			)
		)
	}
}
