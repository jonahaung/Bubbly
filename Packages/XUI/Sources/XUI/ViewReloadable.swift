import Foundation

@MainActor
public protocol ViewReloadable: AnyObject {
	var reloadID: Int { get set }
	func layoutIfNeeded()
}

public extension ViewReloadable {
	func layoutIfNeeded() {
		reloadID += 1
	}
}
