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
		guard let path = Bundle.main.path(
			forResource: "bubbly-3c6a9-firebase-adminsdk-fbsvc-833d99cb5b",
			ofType: "json"
		) else {
			throw PushNotificationError.serviceAccountNotFound
		}

		let data = try Data(contentsOf: URL(fileURLWithPath: path))
		return try JSONDecoder().decode(ServiceAccountCredentials.self, from: data)
	}
    private static func decode(from data: Data) throws -> ServiceAccountCredentials {
        guard !data.isEmpty else {
            throw PushNotificationError.serviceAccountNotFound
        }

        return try JSONDecoder().decode(ServiceAccountCredentials.self, from: data)
    }
}
