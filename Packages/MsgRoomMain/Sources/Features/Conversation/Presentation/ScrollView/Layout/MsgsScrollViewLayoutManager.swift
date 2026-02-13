import Database
import SwiftUI

final class MsgsScrollViewLayoutManager {
	let cache: MsgsScrollViewLayoutCache
	private(set) var selectedMsg: SelectedMsg?

	init(cache: MsgsScrollViewLayoutCache) {
		self.cache = cache
	}

	func updateSelectedMsg(_ newValue: SelectedMsg?) {
		selectedMsg = newValue
	}
}
