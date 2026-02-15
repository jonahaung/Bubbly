import Database
import Foundation

@MainActor
public protocol DependencyContainer: Sendable {
	var currentUserRepository: CurrentUserRepository { get }
	var contactsRepository: ContactsRepositoryProtocol { get }
	init(currentUserRepository: CurrentUserRepository,
	     contactsRepository: any ContactsRepositoryProtocol)
}
