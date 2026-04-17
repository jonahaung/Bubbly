// © 2026 Aung Ko Min

import SwiftUI
import XUI

public enum MsgRecipient: Int, Codable, Sendable, Hashable {
    case outgoing
    case incoming
    case system
}
