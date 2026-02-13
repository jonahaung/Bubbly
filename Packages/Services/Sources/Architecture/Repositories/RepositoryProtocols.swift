import Database
import Foundation
import SwiftUI

public protocol MessageRepositoryProtocol {}
public protocol ConversationRepositoryProtocol {}
public protocol UserRepositoryProtocol {}
public protocol TypingRepositoryProtocol {}
public protocol MediaRepositoryProtocol {}
public protocol LocalStorageProtocol {}

@MainActor
public protocol CurrentUserRepositoryProtocol {
	var model: CurrentUserModel { get set }
	init(_ model: CurrentUserModel)
}

@MainActor
public protocol ContactsRepositoryProtocol: Observable, Sendable {
	var contacts: [Contact] { get set }
	var groups: [Database.Group] { get set }

	@concurrent
	func fetchData() async throws
	@concurrent
	func syncGroups(currentUser: CurrentUserModel) async throws
	@concurrent
	func syncContacts() async throws
	func contact(for uid: String) -> Contact?
	@concurrent
	func delete(uid: String) async throws
	@concurrent
	func refresh() async throws
}
