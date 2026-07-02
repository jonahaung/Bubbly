// © 2026 Aung Ko Min

import Foundation

public struct MessageDeepLinkRoute: Hashable, Sendable {
    public let msgID: String

    public init(msgID: String) {
        self.msgID = msgID
    }

    public init?(query: DeeplinkQueryReader) {
        guard let msgID = query.require(.id) else {
            return nil
        }
        self.msgID = msgID
    }

    public func encode(into writer: inout DeeplinkQueryWriter) {
        writer.set(.id, msgID)
    }
}
