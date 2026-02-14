import SwiftUI
import XUI

public enum MsgRecipient: Int, Codable, Sendable, Hashable {
	case send
	case receive
	case assistant
}
