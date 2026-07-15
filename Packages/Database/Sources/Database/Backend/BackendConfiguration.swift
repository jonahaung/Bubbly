import Foundation

enum BackendConfiguration {
    static func baseURL() throws -> URL {
        let environmentValue = ProcessInfo.processInfo.environment["BUBBLY_API_BASE_URL"]
        let infoValue = Bundle.main.object(forInfoDictionaryKey: "BubblyAPIBaseURL") as? String
        let value: String?

        if let environmentValue, !environmentValue.isEmpty {
            value = environmentValue
        } else if let infoValue, !infoValue.isEmpty, !infoValue.contains("$(") {
            value = infoValue
        } else {
            #if DEBUG
            value = "http://127.0.0.1:8080"
            #else
            value = nil
            #endif
        }

        guard let value else {
            throw BackendAPIError.missingConfiguration
        }
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            throw BackendAPIError.invalidConfiguration
        }
        #if !DEBUG
        guard scheme == "https" else {
            throw BackendAPIError.invalidConfiguration
        }
        #endif
        return url
    }
}
