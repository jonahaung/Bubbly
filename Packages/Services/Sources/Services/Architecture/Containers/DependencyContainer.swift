// © 2026 Aung Ko Min

import Database
import Foundation

@MainActor
public protocol DependencyContainer: Sendable {
    var currentUserRepository: CurrentUserRepository { get }
    init(
        currentUserRepository: CurrentUserRepository,
    )
}
