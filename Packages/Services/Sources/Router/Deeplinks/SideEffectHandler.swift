//
//  SideEffectHandler.swift
//  Services
//
//  Created by Aung Ko Min on 29/1/26.
//

import Database
import Foundation

public struct SideEffectHandler: Sendable {
	public var run: @Sendable (DeeplinkAction.SideEffect) async throws -> Void

	public init(run: @escaping @Sendable (DeeplinkAction.SideEffect) async throws -> Void) {
        self.run = run
    }
	public static let `default` =  SideEffectHandler { effect in
		switch effect {
		case .prepareForConversation(let id):
			ConversationInitializer.start(conID: id, refetch: false)
		case .track(let event, let props):
			print("Track \(event) \(props)")
		case .requireAuth:
			break
		case .prepareForContactDetails(id: let id):
			let contact = try await ContactRepo.getOrCreate(for: id, refetch: false)
			await Router.shared.pushToNav(NavPath.contactDetails(contact))
		}
	}
}
