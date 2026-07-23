import Foundation

public extension BackendAPIClient {
    @discardableResult
    func sendPushNotifications(
        messagesByRecipientUserID: [String: String],
        title: String?,
        body: String?,
        conversationID: String,
        deepLink: String?
    ) async throws -> Set<String> {
        let conversationID = try validatedIdentifier(conversationID, name: "conversation")
        guard !messagesByRecipientUserID.isEmpty, messagesByRecipientUserID.count <= 256,
              title?.count ?? 0 <= 100,
              body?.count ?? 0 <= 4_096,
              deepLink?.count ?? 0 <= 2_048 else {
            throw BackendAPIError.invalidRequest("The push notification contains invalid values.")
        }
        let recipients = try messagesByRecipientUserID.map { userID, messageContent in
            let userID = try validatedIdentifier(userID, name: "recipient user")
            let messageContent = messageContent.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !messageContent.isEmpty, messageContent.utf8.count <= 32_768 else {
                throw BackendAPIError.invalidRequest("The push notification contains invalid values.")
            }
            return PushNotificationRequest.Recipient(userID: userID, messageContent: messageContent)
        }.sorted { $0.userID < $1.userID }
        let request = PushNotificationRequest(
            recipients: recipients,
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
        let response = try executor.decode(PushNotificationResponse.self, from: data)
        return Set(response.results.compactMap { $0.messageID == nil ? nil : $0.recipientUserID })
    }

    private func validatedIdentifier(_ value: String, name: String) throws -> String {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= 128 else {
            throw BackendAPIError.invalidRequest("The \(name) identifier is invalid.")
        }
        return value
    }
}
