import Database
import Foundation
import Services

extension ChatOverlayView {
	struct Item: Hashable, Sendable, Identifiable {
		let id: String
		var frame: CGRect

		func hash(into hasher: inout Hasher) {
			id.hash(into: &hasher)
		}

		static func == (lhs: Item, rhs: Item) -> Bool {
			lhs.id == rhs.id
		}
	}
}
