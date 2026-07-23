import Foundation

public struct BackendRetryPolicy: Sendable, Equatable {
    public let maximumRetryCount: Int
    public let initialDelay: Duration
    public let maximumDelay: Duration

    public init(
        maximumRetryCount: Int = 2,
        initialDelay: Duration = .milliseconds(250),
        maximumDelay: Duration = .seconds(2)
    ) {
        let initialDelay = max(.zero, initialDelay)
        self.maximumRetryCount = max(0, maximumRetryCount)
        self.initialDelay = initialDelay
        self.maximumDelay = max(initialDelay, maximumDelay, .zero)
    }

    public static let `default` = BackendRetryPolicy()
    public static let disabled = BackendRetryPolicy(maximumRetryCount: 0)

    func delay(forRetry retry: Int) -> Duration {
        min(initialDelay * (1 << min(retry, 20)), maximumDelay)
    }
}

public struct BackendAPIConfiguration: Sendable, Equatable {
    public let baseURL: URL
    public let requestTimeout: TimeInterval
    public let retryPolicy: BackendRetryPolicy

    public init(
        baseURL: URL,
        requestTimeout: TimeInterval = 30,
        retryPolicy: BackendRetryPolicy = .default,
        allowsInsecureHTTP: Bool = false
    ) throws {
        guard let scheme = baseURL.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              baseURL.host != nil,
              baseURL.user == nil,
              baseURL.password == nil,
              baseURL.query == nil,
              baseURL.fragment == nil,
              requestTimeout > 0 else {
            throw BackendAPIError.invalidConfiguration
        }
        guard scheme == "https" || allowsInsecureHTTP else {
            throw BackendAPIError.insecureConfiguration
        }
        self.baseURL = baseURL
        self.requestTimeout = requestTimeout
        self.retryPolicy = retryPolicy
    }

    public static func application() throws -> BackendAPIConfiguration {
        let environmentValue = ProcessInfo.processInfo.environment["BUBBLY_API_BASE_URL"]
        let infoValue = Bundle.main.object(forInfoDictionaryKey: "BubblyAPIBaseURL") as? String
        let rawValue = [environmentValue, infoValue]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty && !$0.contains("$(") }

        guard let rawValue else {
            throw BackendAPIError.missingConfiguration
        }
        guard let baseURL = URL(string: rawValue) else {
            throw BackendAPIError.invalidConfiguration
        }

        #if DEBUG
        return try BackendAPIConfiguration(baseURL: baseURL, allowsInsecureHTTP: true)
        #else
        return try BackendAPIConfiguration(baseURL: baseURL)
        #endif
    }
}
