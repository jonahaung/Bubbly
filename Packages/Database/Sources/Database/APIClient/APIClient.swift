import FirebaseAuth
import Foundation

public typealias APIAccessTokenProvider = @Sendable (_ forceRefresh: Bool) async throws -> String

public struct APIClient: Sendable {
    public static let shared = APIClient()

    let executor: BackendRequestExecutor

    public init(session: URLSession = APIClient.makeSession()) {
        executor = BackendRequestExecutor(
            configurationProvider: BackendAPIConfiguration.application,
            accessTokenProvider: APIClient.firebaseAccessToken,
            transport: URLSessionBackendHTTPTransport(session: session)
        )
    }

    public init(
        configuration: BackendAPIConfiguration,
        session: URLSession = APIClient.makeSession(),
        accessTokenProvider: @escaping APIAccessTokenProvider
    ) {
        executor = BackendRequestExecutor(
            configurationProvider: { configuration },
            accessTokenProvider: accessTokenProvider,
            transport: URLSessionBackendHTTPTransport(session: session)
        )
    }

    init(
        configuration: BackendAPIConfiguration,
        transport: any BackendHTTPTransport,
        accessTokenProvider: @escaping APIAccessTokenProvider
    ) {
        executor = BackendRequestExecutor(
            configurationProvider: { configuration },
            accessTokenProvider: accessTokenProvider,
            transport: transport
        )
    }

    public static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = false
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.httpMaximumConnectionsPerHost = 8
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }

    private static func firebaseAccessToken(forceRefresh: Bool) async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw BackendAPIError.notAuthenticated
        }
        return try await user.getIDTokenResult(forcingRefresh: forceRefresh).token
    }
}
