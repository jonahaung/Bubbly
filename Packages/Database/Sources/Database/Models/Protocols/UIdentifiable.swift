// © 2026 Aung Ko Min

import Foundation

// MARK: - UIdentifiable

public protocol UIdentifiable: Identifiable {
    associatedtype UID = String
    var uid: UID { get }
}

public extension UIdentifiable {
    var id: UID {
        uid
    }
}
