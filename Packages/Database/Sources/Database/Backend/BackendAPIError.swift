import Foundation

public enum BackendAPIError: Error, LocalizedError, Sendable, Equatable {
    case missingConfiguration
    case invalidConfiguration
    case insecureConfiguration
    case invalidRequest(String)
    case notAuthenticated
    case invalidResponse
    case network(URLError.Code)
    case transportFailure
    case rejected(statusCode: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            "The Bubbly API base URL is not configured."
        case .invalidConfiguration:
            "The Bubbly API configuration is invalid."
        case .insecureConfiguration:
            "The Bubbly API requires HTTPS."
        case let .invalidRequest(message):
            message
        case .notAuthenticated:
            "Authentication is required."
        case .invalidResponse:
            "The server returned an invalid response."
        case let .network(code):
            URLError(code).localizedDescription
        case .transportFailure:
            "The request could not be completed."
        case let .rejected(statusCode, message):
            message.isEmpty ? "The server rejected the request with status \(statusCode)." : message
        }
    }
}
