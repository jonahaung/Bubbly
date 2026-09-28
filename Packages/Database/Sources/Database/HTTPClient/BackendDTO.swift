//  BackendDTO.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Shared
import Foundation

struct PushNotificationRequest: Encodable, Sendable {
    let recipients: [Recipient]
    let title: String?
    let body: String?
    let conversationID: String
    let deepLink: String?

    struct Recipient: Encodable, Sendable {
        let userID: String
        let messageContent: String
    }
}

struct PushNotificationResponse: Decodable, Sendable {
    let results: [Result]

    struct Result: Decodable, Sendable {
        let recipientUserID: String
        let messageID: String?
        let failureCode: String?
    }
}

struct BackendErrorResponse: Decodable, Sendable {
    let reason: String?
    let error: Bool?
}

struct GroupUpsertRequest: Encodable, Sendable {
    let name: String
    let photoURL: String?
    let members: [String]

    init(_ group: Group) {
        name = group.name
        photoURL = group.photoURL
        members = group.members
    }
}

struct GroupListResponse: Decodable, Sendable {
    let items: [Group]
    let nextCursor: String?
}
