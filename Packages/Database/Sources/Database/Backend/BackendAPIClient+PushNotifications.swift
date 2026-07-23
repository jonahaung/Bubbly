import Foundation

public extension BackendAPIClient {
    @discardableResult
    func sendPushNotification(
        recipientUserID: String,
        messageContent: String,
        title: String?,
        body: String?,
        conversationID: String,
        deepLink: String?
    ) async throws -> String {
        let recipientUserID = try validatedIdentifier(recipientUserID, name: "recipient user")
        let conversationID = try validatedIdentifier(conversationID, name: "conversation")
        let messageContent = messageContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageContent.isEmpty, messageContent.utf8.count <= 32_768,
              title?.count ?? 0 <= 100,
              body?.count ?? 0 <= 4_096,
              deepLink?.count ?? 0 <= 2_048 else {
            throw BackendAPIError.invalidRequest("The push notification contains invalid values.")
        }
        let request = PushNotificationRequest(
            recipientUserID: recipientUserID,
            messageContent: messageContent,
            title: title,
            body: body,
            conversationID: conversationID,
            deepLink: deepLink
        )
        let data = try await executor.requiredResponse(
            method: "POST",
            path: ["v1", "push-notifications"],
            body: .data(try executor.encode(request)),
            contentType: "application/json"
        )
        return try executor.decode(PushNotificationResponse.self, from: data).messageID
    }

    private func validatedIdentifier(_ value: String, name: String) throws -> String {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= 128 else {
            throw BackendAPIError.invalidRequest("The \(name) identifier is invalid.")
        }
        return value
    }
}
