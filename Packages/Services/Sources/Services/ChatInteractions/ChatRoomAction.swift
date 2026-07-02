// © 2026 Aung Ko Min

import Database
import SwiftUI

public extension EnvironmentValues {
    @Entry var sendChatRoomAction: (@Sendable (AnyMsgData) -> Void)?
}
