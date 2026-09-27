import Foundation
import Shared

extension Request {

    struct ContactLookup: APIRequest {
        typealias Response = [Contact]
        struct Body: Encodable {
            let mobileNumbers: [String]
        }
        let subPath: Shared.APIPath.SubPath = .contacts
        let endPoint: Shared.APIEndPoint = .lookup
        let method: HTTPMethod = .post
        let body: Encodable?

        init(mobileNumbers: [String]) {
            body = Body(mobileNumbers: mobileNumbers)
        }
    }

    struct ContactUpdate<T: ContactRepresentableSendable>: APIRequest {
        typealias Response = T
        let method: HTTPMethod = .put
        let subPath: Shared.APIPath.SubPath = .contacts
        let endPoint: Shared.APIEndPoint = .put
        let body: Encodable?

        init(modal: T) {
            body = modal
        }
    }
    struct ContactGet<T: ContactRepresentableSendable>: APIRequest {
        typealias Response = T
        let method: HTTPMethod = .get
        let subPath: Shared.APIPath.SubPath = .contacts
        let endPoint: Shared.APIEndPoint

        init(uid: String) {
            endPoint = .custom(uid)
        }
    }
}

struct PushTokenUpdateRequest: Encodable, Sendable {
    let pushToken: String
}

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
