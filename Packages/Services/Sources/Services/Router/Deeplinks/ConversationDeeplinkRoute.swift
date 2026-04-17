// © 2026 Aung Ko Min

import Foundation

public struct ConversationDeeplinkRoute: Hashable, Sendable {
    public let conID: String

    public init(conID: String) {
        self.conID = conID
    }

    public init?(query: DeeplinkQueryReader) {
        guard let conID = query.require(.id) else {
            return nil
        }
        self.conID = conID
    }

    public func encode(into writer: inout DeeplinkQueryWriter) {
        writer.set(.id, conID)
    }
}
