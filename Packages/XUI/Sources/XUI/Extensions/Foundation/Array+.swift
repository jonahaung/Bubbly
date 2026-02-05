//
//  Array+.swift
//  XUI
//
//  Created by Aung Ko Min on 16/3/25.
//

import Foundation

public extension Array {
	@inlinable
	func insertionIndex(
		for newElement: Element,
		by keyPath: KeyPath<Element, some Comparable>
	) -> Int {
		var low = startIndex
		var high = endIndex

		let newValue = newElement[keyPath: keyPath]

		while low < high {
			let mid = index(low, offsetBy: distance(from: low, to: high) / 2)
			if self[mid][keyPath: keyPath] < newValue {
				low = index(after: mid)
			} else {
				high = mid
			}
		}
		return low
	}
}

public extension Array {
	@inlinable
	var enumerated: [(index: Int, element: Element)] {
		self.enumerated().map { (index: $0.offset, element: $0.element) }
	}
}

public extension Array where Element: Identifiable {
	@inlinable
	func elementsAround(id: Element.ID, radius: Int) -> [Element]? {
		guard let index = firstIndex(where: { $0.id == id }) else {
			return nil
		}
		let safeRadius = Swift.max(0, radius)
		let lowerBound = Swift.max(0, index - safeRadius)
		let upperBound = Swift.min(count - 1, index + safeRadius)
		return Array(self[lowerBound ... upperBound])
	}
}
public extension Array where Element: Identifiable, Element.ID: Hashable {
	@inlinable
	func duplicates() -> [Element] {
		var seen = Set<Element.ID>()
		var duplicates: [Element] = []
		duplicates.reserveCapacity(count / 2)

		for item in self where !seen.insert(item.id).inserted {
			duplicates.append(item)
		}

		return duplicates
	}
}

public extension Array {
	@inlinable
	var middleElement: Element? {
		guard !isEmpty else { return nil }
		return self[(count - 1) / 2]
	}
}

public extension Array where Element: Hashable {
	@inlinable
	mutating func appendUnique(_ newElement: Element) {
		if !contains(newElement) { append(newElement) }
	}

	@inlinable
	mutating func appendUnique<S: Sequence>(contentsOf newElements: S) where S.Element == Element {
		var seen = Set(self)
		for element in newElements where seen.insert(element).inserted {
			append(element)
		}
	}
}

public extension Array where Element: Identifiable {
	@inlinable
	mutating func appendUniqueByID(_ newElement: Element) {
		if let index = firstIndex(where: { $0.id == newElement.id }) {
			self[index] = newElement
		} else {
			append(newElement)
		}
	}
}

public extension Array where Element: Identifiable {
	@inlinable
	func next(of index: Int) -> Element? {
		guard index + 1 < count else { return nil }
		return self[index + 1]
	}
	@inlinable
	func previous(of index: Int) -> Element? {
		guard index > 0 else { return nil }
		return self[index - 1]
	}
	@inlinable
	func next(after item: Element) -> Element? {
		guard let index = index(of: item.id), index + 1 < count else { return nil }
		return next(of: index)
	}
	@inlinable
	func previous(before item: Element) -> Element? {
		guard let index = index(of: item.id), index > 0 else { return nil }
		return previous(of: index)
	}
}

public extension Array where Element: Identifiable {
	@inlinable
	func index(of id: Element.ID) -> Int? {
		firstIndex(where: { $0.id == id })
	}
}

public extension Array {
	// MARK: - Non-mutating: Removing
	@inlinable
	func removingPrefix(_ count: Int) -> [Element] {
		guard count > 0 else { return self }
		return Array(dropFirst(count))
	}
	@inlinable
	func removingSuffix(_ count: Int) -> [Element] {
		guard count > 0 else { return self }
		return Array(dropLast(count))
	}

	// MARK: - Non-mutating: Taking
	@inlinable
	func takingPrefix(_ count: Int) -> [Element] {
		guard count > 0 else { return [] }
		return Array(prefix(count))
	}
	@inlinable
	func takingSuffix(_ count: Int) -> [Element] {
		guard count > 0 else { return [] }
		return Array(suffix(count))
	}

	// MARK: - Non-mutating: Safe Slice
	@inlinable
	func safeSlice(_ range: Range<Int>) -> [Element] {
		let lower = Swift.max(range.lowerBound, startIndex)
		let upper = Swift.min(range.upperBound, endIndex)
		guard lower < upper else { return [] }
		return Array(self[lower ..< upper])
	}

	// MARK: - Mutating
	@inlinable
	mutating func removePrefix(_ count: Int) {
		guard count > 0 else { return }
		if count >= self.count {
			removeAll()
		} else {
			removeFirst(count)
		}
	}
	@inlinable
	mutating func removeSuffix(_ count: Int) {
		guard count > 0 else { return }
		if count >= self.count {
			removeAll()
		} else {
			removeLast(count)
		}
	}
}

public extension Array where Element: Identifiable, Element.ID: Hashable {
	/// Appends elements from `newElements`, ensuring uniqueness.
	/// - Parameters:
	///   - newElements: The elements to append.
	///   - replaceExisting: If `true`, replaces existing elements with the same ID.
	@inlinable
	mutating func appendMerge(contentsOf newElements: [Element], replaceExisting: Bool = false) {
		guard !newElements.isEmpty else { return }

		var indexByID: [Element.ID: Int] = [:]
		indexByID.reserveCapacity(count)
		for (index, element) in enumerated() {
			indexByID[element.id] = index
		}

		var seenNewIDs = Set<Element.ID>()
		for element in newElements where seenNewIDs.insert(element.id).inserted {
			if let index = indexByID[element.id] {
				if replaceExisting {
					self[index] = element
				}
			} else {
				append(element)
				indexByID[element.id] = count - 1
			}
		}
	}

	/// Inserts elements from `newElements` at the given index, ensuring uniqueness.
	/// - Parameters:
	///   - newElements: The elements to insert.
	///   - index: Insertion index in the array.
	///   - replaceExisting: If `true`, replaces existing elements with the same ID.
	@inlinable
	mutating func insertMerge(contentsOf newElements: [Element], at index: Int, replaceExisting: Bool = false) {
		guard !newElements.isEmpty else { return }

		let insertionIndex = Swift.max(0, Swift.min(index, count))

		if insertionIndex == count {
			appendMerge(contentsOf: newElements, replaceExisting: replaceExisting)
			return
		}

		var uniqueNewElements: [Element] = []
		var seenNewIDs = Set<Element.ID>()

		for element in newElements where seenNewIDs.insert(element.id).inserted {
			uniqueNewElements.append(element)
		}

		guard !uniqueNewElements.isEmpty else { return }

		var result: [Element] = []
		var resultIDs = Set<Element.ID>()
		let newIDs = Set(uniqueNewElements.map(\.id))

		// Add elements before insertion point
		for idx in 0 ..< insertionIndex {
			let element = self[idx]
			if replaceExisting, newIDs.contains(element.id) {
				continue
			}
			if resultIDs.insert(element.id).inserted {
				result.append(element)
			}
		}

		// Add new elements
		for element in uniqueNewElements where resultIDs.insert(element.id).inserted {
			result.append(element)
		}

		// Add elements after insertion point
		for idx in insertionIndex ..< count {
			let element = self[idx]
			if replaceExisting, newIDs.contains(element.id) {
				continue
			}
			if resultIDs.insert(element.id).inserted {
				result.append(element)
			}
		}

		self = result
	}

	/// Convenience method to merge elements without specifying position
	/// - Parameters:
	///   - newElements: The elements to merge.
	///   - replaceExisting: If `true`, replaces existing elements with the same ID.
	@inlinable
	mutating func merge(contentsOf newElements: [Element], replaceExisting: Bool = false) {
		appendMerge(contentsOf: newElements, replaceExisting: replaceExisting)
	}
}
