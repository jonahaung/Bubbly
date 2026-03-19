import Foundation

public struct ServiceAccountCredentials: Codable, Sendable {
    public let type: String
    public let projectID: String
    public let privateKeyID: String
    public let privateKey: String
    public let clientEmail: String
    public let clientID: String
    public let authURI: String
    public let tokenURI: String
    public let authProviderX509CertURL: String
    public let clientX509CertURL: String
    public let universeDomain: String

    public enum CodingKeys: String, CodingKey {
        case type
        case projectID = "project_id"
        case privateKeyID = "private_key_id"
        case privateKey = "private_key"
        case clientEmail = "client_email"
        case clientID = "client_id"
        case authURI = "auth_uri"
        case tokenURI = "token_uri"
        case authProviderX509CertURL = "auth_provider_x509_cert_url"
        case clientX509CertURL = "client_x509_cert_url"
        case universeDomain = "universe_domain"
    }

    private static let empty = ServiceAccountCredentials(
        type: "",
        projectID: "",
        privateKeyID: "",
        privateKey: "",
        clientEmail: "",
        clientID: "",
        authURI: "",
        tokenURI: "",
        authProviderX509CertURL: "",
        clientX509CertURL: "",
        universeDomain: ""
    )

    public static let shared: ServiceAccountCredentials = {
        do {
            return try load()
        } catch {
            return empty
        }
    }()

    private static func load() throws -> ServiceAccountCredentials {
        let environment = ProcessInfo.processInfo.environment

        if let json = environment["FIREBASE_SERVICE_ACCOUNT_JSON"],
           let data = json.data(using: .utf8) {
            return try decode(from: data)
        }

        if let path = environment["FIREBASE_SERVICE_ACCOUNT_PATH"],
           !path.isEmpty {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            return try decode(from: data)
        }

        if let encoded = environment["FIREBASE_SERVICE_ACCOUNT_JSON_BASE64"],
           let data = Data(base64Encoded: encoded) {
            return try decode(from: data)
        }

        throw PushNotificationError.serviceAccountNotFound
    }

    private static func decode(from data: Data) throws -> ServiceAccountCredentials {
        guard !data.isEmpty else {
            throw PushNotificationError.serviceAccountNotFound
        }

        return try JSONDecoder().decode(ServiceAccountCredentials.self, from: data)
    }
}
