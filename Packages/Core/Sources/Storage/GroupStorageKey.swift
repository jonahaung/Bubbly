//
//  GroupStorageKey.swift
//  Core
//
//  Created by Aung Ko Min on 15/8/25.
//

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

extension GroupStorageKey {
	public enum Router: String, Hashable, Sendable {
		case targetedDeepLinkPath
	}

	public enum Device: String, Hashable, Sendable {
		case deviceToken
	}

	public enum Auth: String, Hashable, Sendable {
		case currentUserID, authToken
	}

	public enum Layout: String, Hashable, Sendable {
		case chatMsgSpacing
	}

	public enum Limit: String, Hashable, Sendable {
		case paginationPageSize
		case minutesForChatMsgGrouping
	}

	public enum Security: Hashable, Sendable, CustomStringConvertible {
		case privateKey(id: String)
		case publicKey(id: String)

		public var description: String {
			switch self {
			case .privateKey(let id):
				"privateKey.\(id)"
			case .publicKey(let id):
				"publicKey.\(id)"
			}
		}
	}
}

extension GroupStorageKey {
	public var value: String {
		var key: String {
			switch self {
			case .layout(let layout):
				layout.rawValue
			case .security(let security):
				security.description
			case .device(let device):
				device.rawValue
			case .auth(let auth):
				auth.rawValue
			case .custom(let key):
				key
			case .limit(let limit):
				limit.rawValue
			case .router(let router):
				router.rawValue
			}
		}
		return AppInformation.appID + "." + key
	}
}
