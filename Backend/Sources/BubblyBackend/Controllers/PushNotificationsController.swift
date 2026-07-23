import Fluent
import Vapor

struct PushNotificationsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.post("v1", "push-notifications", use: send)
    }

    private func send(request: Request) async throws -> PushNotificationResponse {
        let principal = try request.auth.require(FirebasePrincipal.self)
        let notification = try request.content
            .decode(PushNotificationRequest.self)
            .validated(senderUserID: principal.userID)
        guard let recipient = try await ContactRepository.find(
            userID: notification.recipientUserID,
            on: request.db
        ) else {
            throw Abort(.notFound)
        }
        let pushToken = recipient.pushToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pushToken.isEmpty, pushToken.count <= 4_096 else {
            throw Abort(.conflict, reason: "Recipient does not have a push token")
        }
        let messageID = try await request.application.pushNotificationSender.send(
            notification,
            deviceToken: pushToken,
            client: request.client
        )
        return PushNotificationResponse(messageID: messageID)
    }
}
