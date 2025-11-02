//
//  StorageKeys.swift
//  Core
//
//  Created by Aung Ko Min on 15/8/25.
//

import Foundation

public enum StorageKeys {
	case device(Device)
	case auth(StorageKeys.Auth)
	case layout(Layout)
	case security(Security)
	case limit(Limit)
	case custom(String)
	case router(Router)
}

public extension StorageKeys {
	enum Router: String {
		case targetedDeepLinkPath
	}
	enum Device: String {
		case deviceToken
	}
	enum Auth: String {
		case currentUserID, authToken
	}
	enum Layout: String {
		case chatMsgSpacing
	}
	enum Limit: String {
		case paginationPageSize
		case minutesForChatMsgGrouping
	}
	enum Security: CustomStringConvertible {
		case privateKey(id: String)
		case publicKey(id: String)

		public var description: String {
			switch self {
			case .privateKey(let id):
				return "privateKey.\(id)"
			case .publicKey(let id):
				return "publicKey.\(id)"
			}
		}
	}
}
public extension StorageKeys {
	var value: String {
		var key: String {
			switch self {
			case .layout(let layout):
				return layout.rawValue
			case .security(let security):
				return security.description
			case .device(let device):
				return device.rawValue
			case .auth(let auth):
				return auth.rawValue
			case .custom(let key):
				return key
			case .limit(let limit):
				return limit.rawValue
			case .router(let router):
				return router.rawValue
			}
		}
		return AppInformation.appID + "." + key
	}
}
