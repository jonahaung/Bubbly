// © 2026 Aung Ko Min

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
            do {
                try await ConversationInitializer.start(conID: id, refetch: false)
            } catch {
                try await ConversationInitializer.start(conID: id, refetch: true)
            }
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
