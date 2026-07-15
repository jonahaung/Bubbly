import Foundation

struct ContactLookupRequest: Encodable, Sendable {
    let mobileNumbers: [String]
}

struct ProfileUpdateRequest: Encodable, Sendable {
    let name: String
    let mobile: String
    let pushToken: String
    let publicKeyString: String

    init(_ model: CurrentUserModel) {
        name = model.name
        mobile = model.mobile
        pushToken = model.pushToken
        publicKeyString = model.publicKeyString
    }
}

struct PushTokenUpdateRequest: Encodable, Sendable {
    let pushToken: String
}

struct BackendErrorResponse: Decodable, Sendable {
    let reason: String?
    let error: Bool?
}
