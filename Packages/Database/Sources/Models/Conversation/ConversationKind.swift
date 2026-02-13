import Foundation

public enum ConversationKind: Codable, Sendable, Hashable {
	case contact(_ contact: Contact)
	case group(_ group: Group)
}
