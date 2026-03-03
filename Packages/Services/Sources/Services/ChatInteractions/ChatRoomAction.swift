//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import SwiftUI

public extension EnvironmentValues {
    @Entry var sendChatRoomAction: (@Sendable (AnyMsgData) -> Void)?
}
