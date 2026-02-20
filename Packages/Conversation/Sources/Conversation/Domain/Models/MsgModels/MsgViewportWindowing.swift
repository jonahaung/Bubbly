import Foundation

struct MsgViewportWindowing {
	let windowSize: Int
	let edgeThreshold: Int
	let lead: Int

	func centeredWindow(on index: Int, totalCount: Int) -> Range<Int> {
		guard totalCount > 0 else { return 0 ..< 0 }
		if totalCount <= windowSize {
			return 0 ..< totalCount
		}
		let half = windowSize / 2
		var lower = max(0, index - half)
		var upper = min(totalCount, lower + windowSize)
		if upper - lower < windowSize {
			lower = max(0, upper - windowSize)
		}
		return lower ..< upper
	}

	func defaultWindow(totalCount: Int) -> Range<Int> {
		guard totalCount > 0 else { return 0 ..< 0 }
		let lower = max(0, totalCount - min(windowSize, totalCount))
		return lower ..< totalCount
	}

	func normalized(_ window: Range<Int>, totalCount: Int) -> Range<Int> {
		guard totalCount > 0 else { return 0 ..< 0 }
		let lower = max(0, min(window.lowerBound, totalCount))
		let upper = max(lower, min(window.upperBound, totalCount))
		if lower == upper {
			return defaultWindow(totalCount: totalCount)
		}
		return lower ..< upper
	}

	func ensureBounds(_ window: Range<Int>, totalCount: Int) -> Range<Int> {
		guard totalCount > 0 else { return 0 ..< 0 }
		if window.isEmpty {
			return defaultWindow(totalCount: totalCount)
		}
		let lower = max(0, min(window.lowerBound, totalCount))
		let upper = max(lower, min(window.upperBound, totalCount))
		if lower == upper {
			return defaultWindow(totalCount: totalCount)
		}
		if upper - lower > windowSize {
			return lower ..< min(totalCount, lower + windowSize)
		}
		return lower ..< upper
	}

	func adjustAroundVisible(index: Int, current: Range<Int>, totalCount: Int) -> Range<Int> {
		guard totalCount > windowSize else {
			return 0 ..< totalCount
		}
		if current.isEmpty {
			return centeredWindow(on: index, totalCount: totalCount)
		}
		if index <= current.lowerBound + edgeThreshold {
			let lower = max(0, index - lead)
			let upper = min(totalCount, lower + windowSize)
			return lower ..< upper
		}
		if index >= current.upperBound - edgeThreshold {
			let upper = min(totalCount, index + lead)
			let lower = max(0, upper - windowSize)
			return lower ..< upper
		}
		return current
	}

	func adjustForMutation(index: Int, inserted: Bool, current: Range<Int>,
	                       totalCount: Int) -> Range<Int> {
		guard inserted else {
			return ensureBounds(current, totalCount: totalCount)
		}
		guard !current.isEmpty else {
			return defaultWindow(totalCount: totalCount)
		}
		if index < current.lowerBound {
			return (current.lowerBound + 1) ..< min(totalCount, current.upperBound + 1)
		}
		if current.contains(index) {
			let upper = min(totalCount, current.upperBound + 1)
			let lower = max(0, upper - min(windowSize, totalCount))
			return lower ..< upper
		}
		if index >= current.upperBound, current.upperBound >= totalCount - 1 {
			let upper = totalCount
			let lower = max(0, upper - min(windowSize, totalCount))
			return lower ..< upper
		}
		return ensureBounds(current, totalCount: totalCount)
	}
}

