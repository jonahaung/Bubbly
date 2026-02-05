//
//  MsgRoomEntryPoint.swift
//  Services
//
//  Created by Aung Ko Min on 3/2/25.
//

import Core
import Database
import FirebaseAuth
import Services
import SwiftUI
import XUI

private struct MsgRoomEntryPointModifier: ViewModifier, ErrorPresenter {

	@LazyState private var currentUser: CurrentUser
	@LazyState private var contactStore = ContactStore.shared
	@LazyState private var router = Router.shared
	init(_ currentUser: CurrentUserModel) {
		_currentUser = .init(wrappedValue: .init(currentUser))
	}

	func body(content: Content) -> some View {
		content
			.environment(router)
			.environment(\.currentUser, currentUser.model)
			.environment(contactStore)
			.task {

				do {
					try await contactStore.fetchData()
				} catch {
					log(error)
				}
			}
	}
}

extension View {
	public func msgRoomEntryPoint(_ currentUser: CurrentUserModel) -> some View {
		ModifiedContent(
			content: self,
			modifier: MsgRoomEntryPointModifier(currentUser)
		)
	}
}
