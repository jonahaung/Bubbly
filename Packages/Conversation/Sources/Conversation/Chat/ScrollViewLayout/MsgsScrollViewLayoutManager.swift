import Database
import SwiftUI
import Services

@Observable
final class MsgsScrollViewLayoutManager: @unchecked Sendable {

	private(set) var selectedMsg: SelectedMsg?
	var config: MsgsScrollViewLayoutConfiguration
	private var sizeStore = [MsgsScrollViewLayout.SubviewKey: CGSize]()
	private var cacheStore = [MsgsScrollViewLayout.CacheKey: MsgsScrollViewLayout.Cache]()

	init(config: MsgsScrollViewLayoutConfiguration) {
		self.config = config
	}

	func updateSelectedMsg(_ newValue: SelectedMsg?) {
		selectedMsg = newValue
	}
}

extension MsgsScrollViewLayoutManager {
	func size(for key: MsgsScrollViewLayout.SubviewKey) -> CGSize? {
		return sizeStore[key]
	}
	func set(size: CGSize, for key: MsgsScrollViewLayout.SubviewKey) {
		sizeStore[key] = size
	}
}

extension MsgsScrollViewLayoutManager {
	func cache(for key: MsgsScrollViewLayout.CacheKey) -> MsgsScrollViewLayout.Cache? {
		cacheStore[key]
	}
	func set(cache: MsgsScrollViewLayout.Cache, for key: MsgsScrollViewLayout.CacheKey) {
		cacheStore[key] = cache
	}
}
