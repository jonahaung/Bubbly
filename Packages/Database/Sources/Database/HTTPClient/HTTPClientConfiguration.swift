import Foundation

public struct HTTPClientConfiguration: Sendable, Equatable {
    public static let applicationBaseURLOverrideKey = "BubblyAPIBaseURLOverride"

    public let baseURL: URL
    public let requestTimeout: TimeInterval
    public let retryPolicy: HTTPRetryPolicy

    public init(
        baseURL: URL,
        requestTimeout: TimeInterval = 30,
        retryPolicy: HTTPRetryPolicy = .default,
        allowsInsecureHTTP: Bool = false
    ) throws {
        guard let scheme = baseURL.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            baseURL.host != nil,
            baseURL.user == nil,
            baseURL.password == nil,
            baseURL.query == nil,
            baseURL.fragment == nil,
            requestTimeout > 0
        else {
            throw HTTPError.invalidConfiguration
        }
        guard scheme == "https" || allowsInsecureHTTP else {
            throw HTTPError.insecureConfiguration
        }
        self.baseURL = baseURL
        self.requestTimeout = requestTimeout
        self.retryPolicy = retryPolicy
    }
}

extension HTTPClientConfiguration {
    public static func application() throws -> Self {
        try application(
            userDefaults: .standard,
            environment: ProcessInfo.processInfo.environment,
            infoDictionaryValue: Bundle.main.object(forInfoDictionaryKey: "BubblyAPIBaseURL") as? String
        )
    }

    public static var applicationBaseURLOverride: String? {
        normalized(UserDefaults.standard.string(forKey: applicationBaseURLOverrideKey))
    }

    public static func setApplicationBaseURLOverride(_ value: String?) throws {
        guard let value = normalized(value) else {
            UserDefaults.standard.removeObject(forKey: applicationBaseURLOverrideKey)
            return
        }
        _ = try configuration(baseURLString: value)
        UserDefaults.standard.set(value, forKey: applicationBaseURLOverrideKey)
    }

    static func application(
        userDefaults: UserDefaults,
        environment: [String: String],
        infoDictionaryValue: String?
    ) throws -> Self {
        let overrideValue = userDefaults.string(forKey: applicationBaseURLOverrideKey)
        let environmentValue = environment["BUBBLY_API_BASE_URL"]
        let rawValue = [environmentValue, overrideValue, infoDictionaryValue]
            .compactMap(normalized)
            .first

        guard let rawValue else {
            throw HTTPError.missingConfiguration
        }
        return try configuration(baseURLString: rawValue)
    }

    private static func normalized(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
            !value.isEmpty,
            !value.contains("$(")
        else {
            return nil
        }
        return value
    }

    private static func configuration(baseURLString: String) throws -> Self {
        guard let baseURL = URL(string: baseURLString) else {
            throw HTTPError.invalidConfiguration
        }

        #if DEBUG
            return try Self(baseURL: baseURL, allowsInsecureHTTP: true)
        #else
            return try Self(baseURL: baseURL)
        #endif
    }
}
