import Foundation

public protocol UIdentifiable: Identifiable {
	associatedtype UID = String
	var uid: UID { get }
}

public extension UIdentifiable {
	var id: UID {
		uid
	}
}
