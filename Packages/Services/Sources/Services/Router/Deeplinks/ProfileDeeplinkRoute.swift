// © 2026 Aung Ko Min

import Foundation

public struct ProfileDeeplinkRoute: Hashable, Sendable {
    public let id: String

    public init(id: String) {
        self.id = id
    }

    public init?(query: DeeplinkQueryReader) {
        guard let id = query.require(.id) else {
            return nil
        }
        self.id = id
    }

    public func encode(into writer: inout DeeplinkQueryWriter) {
        writer.set(.id, id)
    }
}
