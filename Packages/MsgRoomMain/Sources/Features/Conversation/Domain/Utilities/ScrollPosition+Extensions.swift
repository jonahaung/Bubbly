import SwiftUI

public extension ScrollPosition {
	static let userDefined = {
		var position = ScrollPosition()
		position.isPositionedByUser = true
		return position
	}()

	mutating func reset() {
		self = .init()
	}
}
