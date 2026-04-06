
import Database
import FoundationModels
import SwiftData

@Generable
public enum ChatEngineRole: String, Codable, Hashable, CaseIterable {
    case user = "User"
    case assistant = "Assistant"
    case sender = "Sender"
}

extension MsgRecipient {
    var role: ChatEngineRole {
        switch self {
		case .outgoing:
            .sender
		case .incoming:
            .user
        }
    }
}
