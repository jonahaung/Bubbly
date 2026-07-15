import Foundation

public enum BackendAPIError: Error, LocalizedError, Sendable {
    case missingConfiguration
    case invalidConfiguration
    case notAuthenticated
    case invalidResponse
    case rejected(statusCode: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            "The Bubbly API base URL is not configured."
        case .invalidConfiguration:
            "The Bubbly API base URL is invalid."
        case .notAuthenticated:
            "Authentication is required."
        case .invalidResponse:
            "The server returned an invalid response."
        case let .rejected(statusCode, message):
            message.isEmpty ? "The server rejected the request with status \(statusCode)." : message
        }
    }
}
