import Foundation

public enum GroupStorageKey: Hashable, Sendable {
	case device(Device)
	case auth(GroupStorageKey.Auth)
	case layout(Layout)
	case security(Security)
	case limit(Limit)
	case custom(String)
	case router(Router)
}

public extension GroupStorageKey {
	enum Router: String, Hashable, Sendable {
		case targetedDeepLinkPath
		case tappedConversationID
	}

	enum Device: String, Hashable, Sendable {
		case deviceToken, anyMsgData
	}

	enum Auth: String, Hashable, Sendable {
		case currentUserID, authToken
	}

	enum Layout: String, Hashable, Sendable {
		case chatMsgSpacing
	}

	enum Limit: String, Hashable, Sendable {
		case paginationPageSize
		case minutesForChatMsgGrouping
	}

	enum Security: Hashable, Sendable, CustomStringConvertible {
		case privateKey(id: String)
		case publicKey(id: String)

		public var description: String {
			switch self {
			case let .privateKey(id):
				"privateKey.\(id)"
			case let .publicKey(id):
				"publicKey.\(id)"
			}
		}
	}
}

public extension GroupStorageKey {
	var value: String {
		var key: String {
			switch self {
			case let .layout(layout):
				layout.rawValue
			case let .security(security):
				security.description
			case let .device(device):
				device.rawValue
			case let .auth(auth):
				auth.rawValue
			case let .custom(key):
				key
			case let .limit(limit):
				limit.rawValue
			case let .router(router):
				router.rawValue
			}
		}
		return AppInformation.appID + "." + key
	}
}
