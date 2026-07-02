// © 2026 Aung Ko Min

import Foundation

public final class MockDependencyContainer: DependencyContainer {
    public let currentUserRepository: CurrentUserRepository

    public init(
        currentUserRepository: CurrentUserRepository,
    ) {
        self.currentUserRepository = currentUserRepository
    }
}

// MARK: - XEnvironment

public enum XEnvironment: Sendable {
    case development
    case staging
    case production

    public var baseURL: URL {
        switch self {
        case .development:
            URL(string: "https://dev-api.example.com")!
        case .staging:
            URL(string: "https://staging-api.example.com")!
        case .production:
            URL(string: "https://api.example.com")!
        }
    }

    public var webSocketURL: URL {
        switch self {
        case .development:
            URL(string: "wss://dev-api.example.com/ws")!
        case .staging:
            URL(string: "wss://staging-api.example.com/ws")!
        case .production:
            URL(string: "wss://api.example.com/ws")!
        }
    }

    public static var current: XEnvironment {
        #if DEBUG
            .development
        #else
            .production
        #endif
    }
}
