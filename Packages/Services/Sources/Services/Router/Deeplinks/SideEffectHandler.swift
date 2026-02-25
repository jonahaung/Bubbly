import Database
import Foundation

public struct SideEffectHandler: Sendable {
	public var run: @Sendable (DeeplinkAction.SideEffect) async throws -> Void

	public init(run: @escaping @Sendable (DeeplinkAction.SideEffect) async throws -> Void) {
		self.run = run
	}

	public static let `default` = SideEffectHandler { effect in
		switch effect {
		case let .prepareForConversation(id):
			try await ConversationInitializer.start(conID: id, refetch: false)
		case let .track(event, props):
			print("Track \(event) \(props)")
		case .requireAuth:
			break
		case let .prepareForContactDetails(id: id):
			let contact = try await ContactRepo.getOrCreate(uid: id, refetch: false)
			await Router.shared.pushToNav(NavPath.contactDetails(contact))
		}
	}
}
