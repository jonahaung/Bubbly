import Database
import Foundation

@MainActor
public protocol DependencyContainer: Sendable {
	var currentUserRepository: CurrentUserRepositoryProtocol { get }
	var contactsRepository: ContactsRepositoryProtocol { get }
	init(currentUserRepository: any CurrentUserRepositoryProtocol,
	     contactsRepository: any ContactsRepositoryProtocol)
}
