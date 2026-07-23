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
        let userIDs = notification.recipients.map(\.userID)
        let contacts = try await ContactModel.query(on: request.db)
            .filter(\.$firebaseUID ~~ userIDs)
            .all()
        let tokensByUserID = Dictionary(uniqueKeysWithValues: contacts.map {
            ($0.firebaseUID, $0.pushToken.trimmingCharacters(in: .whitespacesAndNewlines))
        })
        let sender = request.application.pushNotificationSender
        let client = request.client
        let results = try await withThrowingTaskGroup(
            of: PushNotificationResponse.Result.self,
            returning: [PushNotificationResponse.Result].self
        ) { group in
            for recipient in notification.recipients {
                group.addTask {
                    guard let pushToken = tokensByUserID[recipient.userID],
                          !pushToken.isEmpty, pushToken.count <= 4_096 else {
                        return .init(
                            recipientUserID: recipient.userID,
                            messageID: nil,
                            failureCode: "missing_push_token"
                        )
                    }
                    do {
                        let messageID = try await sender.send(
                            notification,
                            recipient: recipient,
                            deviceToken: pushToken,
                            client: client
                        )
                        return .init(
                            recipientUserID: recipient.userID,
                            messageID: messageID,
                            failureCode: nil
                        )
                    } catch is CancellationError {
                        throw CancellationError()
                    } catch {
                        return .init(
                            recipientUserID: recipient.userID,
                            messageID: nil,
                            failureCode: "fcm_send_failed"
                        )
                    }
                }
            }
            var results: [PushNotificationResponse.Result] = []
            results.reserveCapacity(notification.recipients.count)
            for try await result in group {
                results.append(result)
            }
            return results.sorted { $0.recipientUserID < $1.recipientUserID }
        }
        return PushNotificationResponse(results: results)
    }
}
