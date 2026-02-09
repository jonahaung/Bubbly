import Foundation

extension String {
	/// Finds all ranges of a substring inside the string
	func ranges(of substring: String,
	            options: CompareOptions = [],
	            locale: Locale? = nil) -> [Range<Index>]
	{
		var ranges: [Range<Index>] = []
		var searchRange = startIndex ..< endIndex

		while let range = range(
			of: substring,
			options: options,
			range: searchRange,
			locale: locale
		) {
			ranges.append(range)
			searchRange = range.upperBound ..< endIndex
		}

		return ranges
	}

	/// Returns all ranges not covered by the provided ranges
	func remainingRanges(from ranges: [Range<Index>]) -> [Range<Index>] {
		guard !ranges.isEmpty else {
			return [startIndex ..< endIndex]
		}

		let sortedRanges = ranges.sorted { $0.lowerBound < $1.lowerBound }
		var result: [Range<Index>] = []
		var currentIndex = startIndex

		for range in sortedRanges {
			if currentIndex < range.lowerBound {
				result.append(currentIndex ..< range.lowerBound)
			}
			currentIndex = range.upperBound
		}

		if currentIndex < endIndex {
			result.append(currentIndex ..< endIndex)
		}

		return result
	}
}
