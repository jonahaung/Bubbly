//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import XUI

public enum MsgRecipient: Int, Codable, Sendable, Hashable {
    case outgoing
    case incoming
}
