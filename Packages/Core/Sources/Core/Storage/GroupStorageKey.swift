//  GroupStorageKey.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import XUI
import Foundation

public enum GroupStorageKey: Hashable, Sendable, CaseNameReflectable {
    case device(Device)
    case auth(GroupStorageKey.Auth)
    case layout(Layout)
    case security(Security)
    case limit(Limit)
    case custom(String)
    case router(Router)
    case conversation(GroupStorageKey.Conversation)
}

public extension GroupStorageKey {
    enum Router: CaseNameReflectable, Sendable {
        case targetedDeepLinkPath
        case tappedConversationID
    }

    enum Device: CaseNameReflectable, Sendable {
        case deviceToken
        case anyMsgData
    }

    enum Auth: CaseNameReflectable, Sendable {
        case currentUserID
        case authToken
    }

    enum Conversation: CaseNameReflectable, Sendable {
        case richTextEnabled
    }

    enum Layout: CaseNameReflectable, Sendable {
        case chatMsgSpacing
    }

    enum Limit: CaseNameReflectable, Sendable {
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
            case let .conversation(conversation):
                conversation.rawValue
            }
        }
        return AppInformation.appID + "." + key
    }
}
