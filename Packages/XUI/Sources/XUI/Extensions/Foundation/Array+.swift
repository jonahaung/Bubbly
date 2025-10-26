//
//  Array+.swift
//  XUI
//
//  Created by Aung Ko Min on 16/3/25.
//

import Foundation

public extension Array {
	func insertionIndex<T: Comparable>(
		for newElement: Element,
		by keyPath: KeyPath<Element, T>
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
	var enumerated: [(index: Int, element: Element)] {
		self.enumerated().map { (index: $0.offset, element: $0.element)}
	}
}
public extension Array where Element: Identifiable {
	func elementsAround(id: Element.ID, radius: Int) -> [Element]? {
		guard let index = firstIndex(where: { $0.id == id }) else {
			return nil
		}
		let lowerBound = Swift.max(0, index - radius)
		let upperBound = Swift.min(count - 1, index + radius)
		return Array(self[lowerBound...upperBound])
	}
}
public extension Array where Element: Identifiable {
	func duplicates() -> [Element] {
		var seen = [Element]()
		var duplicates = [Element]()

		for item in self {
			if seen.contains(where: { $0.id == item.id }) {
				duplicates.append(item)
			} else {
				seen.append(item)
			}
		}

		return duplicates
	}
}

public extension Array where Element: Equatable {
	mutating func appendUnique(_ newElement: Element) {
		if !contains(newElement) {
			append(newElement)
		}
	}
	mutating func appendUnique(contentsOf newElements: [Element]) {
		for element in newElements where !contains(element) {
			append(element)
		}
	}
}
public extension Array where Element: Identifiable {
	func next(of index: Int) -> Element? {
		guard index + 1 < count else { return nil }
		return self[index + 1]
	}
	func previous(of index: Int) -> Element? {
		guard index > 0 else { return nil }
		return self[index - 1]
	}
	func next(after item: Element) -> Element? {
		guard let index = index(of: item.id), index + 1 < count else { return nil }
		return next(of: index)
	}

	func previous(before item: Element) -> Element? {
		guard let index = index(of: item.id), index > 0 else { return nil }
		return previous(of: index)
	}
}
public extension Array where Element: Identifiable {
	func index(of id: Element.ID) -> Int? {
		firstIndex(where: { $0.id == id })
	}
}
public extension Array {
	// MARK: - Non-mutating: Removing

	func removingPrefix(_ count: Int) -> [Element] {
		guard count > 0 else { return self }
		return Array(dropFirst(count))
	}

	func removingSuffix(_ count: Int) -> [Element] {
		guard count > 0 else { return self }
		return Array(dropLast(count))
	}

	// MARK: - Non-mutating: Taking

	func takingPrefix(_ count: Int) -> [Element] {
		guard count > 0 else { return [] }
		return Array(prefix(count))
	}

	func takingSuffix(_ count: Int) -> [Element] {
		guard count > 0 else { return [] }
		return Array(suffix(count))
	}

	// MARK: - Non-mutating: Safe Slice

	func safeSlice(_ range: Range<Int>) -> [Element] {
		let lower = Swift.max(range.lowerBound, startIndex)
		let upper = Swift.min(range.upperBound, endIndex)
		guard lower < upper else { return [] }
		return Array(self[lower..<upper])
	}

	// MARK: - Mutating

	mutating func removePrefix(_ count: Int) {
		guard count > 0 else { return }
		if count >= self.count {
			removeAll()
		} else {
			removeFirst(count)
		}
	}

	mutating func removeSuffix(_ count: Int) {
		guard count > 0 else { return }
		if count >= self.count {
			removeAll()
		} else {
			removeLast(count)
		}
	}
}

public extension Array where Element: Identifiable {

	/// Appends elements from `newElements`, ensuring uniqueness.
	/// - Parameters:
	///   - newElements: The elements to append.
	///   - replaceExisting: If `true`, replaces existing elements with the same ID.
	mutating func appendMerge(contentsOf newElements: [Element], replaceExisting: Bool = false) {
		guard !newElements.isEmpty else { return }

		var existingDict = Dictionary(uniqueKeysWithValues: self.map { ($0.id, $0) })
		var uniqueNewElements: [Element] = []
		var seenNewIDs = Set<Element.ID>()

		// Filter and prepare new elements
		for element in newElements {
			let id = element.id

			// Skip duplicates within newElements itself
			guard seenNewIDs.insert(id).inserted else { continue }

			if replaceExisting || existingDict[id] == nil {
				uniqueNewElements.append(element)
				existingDict[id] = element
			}
		}

		guard !uniqueNewElements.isEmpty else { return }

		// Append to the end
		self += uniqueNewElements
	}

	/// Inserts elements from `newElements` at the given index, ensuring uniqueness.
	/// - Parameters:
	///   - newElements: The elements to insert.
	///   - index: Insertion index in the array.
	///   - replaceExisting: If `true`, replaces existing elements with the same ID.
	mutating func insertMerge(contentsOf newElements: [Element], at index: Int, replaceExisting: Bool = false) {
		guard !newElements.isEmpty else { return }

		let insertionIndex = Swift.max(0, Swift.min(index, count))

		// Handle simple case: inserting at the end (same as append)
		if insertionIndex == count {
			appendMerge(contentsOf: newElements, replaceExisting: replaceExisting)
			return
		}

		var existingDict = Dictionary(uniqueKeysWithValues: self.map { ($0.id, $0) })
		var uniqueNewElements: [Element] = []
		var seenNewIDs = Set<Element.ID>()

		// Filter and prepare new elements
		for element in newElements {
			let id = element.id

			// Skip duplicates within newElements itself
			guard seenNewIDs.insert(id).inserted else { continue }

			if replaceExisting || existingDict[id] == nil {
				uniqueNewElements.append(element)
				existingDict[id] = element
			}
		}

		guard !uniqueNewElements.isEmpty else { return }

		// Rebuild the array with inserted elements
		var result: [Element] = []
		var resultIDs = Set<Element.ID>()

		// Add elements before insertion point
		for i in 0..<insertionIndex {
			let element = self[i]
			if resultIDs.insert(element.id).inserted {
				result.append(element)
			}
		}

		// Add new elements
		for element in uniqueNewElements {
			if resultIDs.insert(element.id).inserted {
				result.append(element)
			}
		}

		// Add elements after insertion point
		for i in insertionIndex..<count {
			let element = self[i]
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
	mutating func merge(contentsOf newElements: [Element], replaceExisting: Bool = false) {
		appendMerge(contentsOf: newElements, replaceExisting: replaceExisting)
	}
}
