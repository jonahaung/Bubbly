// © 2026 Aung Ko Min

import Database
import SwiftUI

public final class SendChatRoomActionHandler: @unchecked Sendable {
    public let handler: @Sendable (AnyMsgData) -> Void
    public init(handler: @escaping @Sendable (AnyMsgData) -> Void) {
        self.handler = handler
    }
}

public extension EnvironmentValues {
    @Entry var sendChatRoomAction: SendChatRoomActionHandler?
}
