import Database
import Foundation

public final class AppDependencyContainer: DependencyContainer {
	public let currentUserRepository: CurrentUserRepository
	public let contactsRepository: any ContactsRepositoryProtocol

	public init(currentUserRepository: CurrentUserRepository,
	            contactsRepository: any ContactsRepositoryProtocol)
	{
		self.currentUserRepository = currentUserRepository
		self.contactsRepository = contactsRepository
	}
}

public struct AppConfiguration: Sendable {
	public let environment: XEnvironment
	public let apiTimeout: TimeInterval
	public let maxRetryAttempts: Int
	public let enableLogging: Bool

	public static let `default` = AppConfiguration(
		environment: .current,
		apiTimeout: 30,
		maxRetryAttempts: 3,
		enableLogging: true
	)

	public init(environment: XEnvironment,
	            apiTimeout: TimeInterval,
	            maxRetryAttempts: Int,
	            enableLogging: Bool)
	{
		self.environment = environment
		self.apiTimeout = apiTimeout
		self.maxRetryAttempts = maxRetryAttempts
		self.enableLogging = enableLogging
	}
}
