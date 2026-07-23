import Foundation
import Vapor

struct PushNotificationRequest: Content, Sendable {
    let recipientUserID: String
    let messageContent: String
    let title: String?
    let body: String?
    let conversationID: String
    let deepLink: String?

    func validated(senderUserID: String) throws -> PushNotificationRequest {
        let recipientUserID = recipientUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        let conversationID = conversationID.trimmingCharacters(in: .whitespacesAndNewlines)
        let messageContent = messageContent.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = body?.trimmingCharacters(in: .whitespacesAndNewlines)
        let deepLink = deepLink?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard recipientUserID != senderUserID,
              !recipientUserID.isEmpty, recipientUserID.count <= 128,
              !conversationID.isEmpty, conversationID.count <= 128,
              !messageContent.isEmpty, messageContent.utf8.count <= 32_768,
              title?.count ?? 0 <= 100,
              body?.count ?? 0 <= 4_096 else {
            throw Abort(.badRequest, reason: "Push notification contains invalid values")
        }
        if let deepLink, !deepLink.isEmpty {
            guard deepLink.count <= 2_048,
                  let url = URL(string: deepLink),
                  let scheme = url.scheme?.lowercased(),
                  ["bubbly", "https"].contains(scheme) else {
                throw Abort(.badRequest, reason: "Push notification deep link is invalid")
            }
        }
        return PushNotificationRequest(
            recipientUserID: recipientUserID,
            messageContent: messageContent,
            title: title?.isEmpty == true ? nil : title,
            body: body?.isEmpty == true ? nil : body,
            conversationID: conversationID,
            deepLink: deepLink?.isEmpty == true ? nil : deepLink
        )
    }
}

struct PushNotificationResponse: Content, Sendable {
    let messageID: String
}
