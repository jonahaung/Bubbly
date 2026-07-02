// © 2026 Aung Ko Min

import Database
import Foundation

// MARK: - AppDependencyContainer

public final class AppDependencyContainer: DependencyContainer {
    
    public let currentUserRepository: CurrentUserRepository

    public init(
        currentUserRepository: CurrentUserRepository,
    ) {
        self.currentUserRepository = currentUserRepository
    }
}

// MARK: - AppConfiguration

public struct AppConfiguration: Sendable {
    public let environment: XEnvironment
    public let apiTimeout: TimeInterval
    public let maxRetryAttempts: Int
    public let enableLogging: Bool

    public static let `default`: AppConfiguration = .init(
        environment: .current,
        apiTimeout: 30,
        maxRetryAttempts: 3,
        enableLogging: true,
    )

    public init(
        environment: XEnvironment,
        apiTimeout: TimeInterval,
        maxRetryAttempts: Int,
        enableLogging: Bool,
    ) {
        self.environment = environment
        self.apiTimeout = apiTimeout
        self.maxRetryAttempts = maxRetryAttempts
        self.enableLogging = enableLogging
    }
}
