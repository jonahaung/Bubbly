//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Database
import SwiftUI

public extension EnvironmentValues {
    @Entry var sendChatRoomAction: (@Sendable (AnyMsgData) -> Void)?
}
