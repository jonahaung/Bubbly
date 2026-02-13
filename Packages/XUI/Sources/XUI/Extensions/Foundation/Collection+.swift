import Foundation

/// Array
public extension Array where Element: Hashable {
	func uniqued() -> [Element] {
		var seen = Set<Element>()
		return filter { seen.insert($0).inserted }
	}
}

public extension Collection where Indices.Iterator.Element == Index {
	subscript(safe index: Index) -> Iterator.Element? {
		(startIndex <= index && index < endIndex) ? self[index] : nil
	}
}

public extension Array {
	mutating func shuffle() {
		if count == 0 {
			return
		}

		for index in 0 ..< (count - 1) {
			let randomIndex = Int.random(in: index ..< count)
			if randomIndex != index {
				swapAt(index, randomIndex)
			}
		}
	}

	func shuffled() -> [Element] {
		var list = self
		list.shuffle()

		return list
	}

	func removeDuplicates(by predicate: (Element, Element) -> Bool) -> Self {
		var result = [Element]()
		for value in self where result.filter({ predicate($0, value) }).isEmpty {
			result.append(value)
		}
		return result
	}

	func removeDuplicates(by keyPath: KeyPath<Element, String>) -> Self {
		removeDuplicates(by: { $0[keyPath: keyPath] == $1[keyPath: keyPath] })
	}

	func removeDuplicates() -> Self where Element: Equatable {
		removeDuplicates(by: ==)
	}
}

public extension Array {
	func groupByKey<Key: Hashable>(keyPath: KeyPath<Element, Key>) -> [Key: [Element]] {
		Dictionary(grouping: self, by: { $0[keyPath: keyPath] })
	}
}

public extension BidirectionalCollection where Iterator.Element: Equatable {
	func nextElement(_ item: Self.Iterator.Element, loop: Bool = false) -> Self.Iterator
		.Element?
	{
		if let itemIndex = firstIndex(of: item) {
			let lastItem: Bool = (index(after: itemIndex) == endIndex)
			if loop, lastItem {
				return first
			} else if lastItem {
				return nil
			} else {
				return self[index(after: itemIndex)]
			}
		}
		return nil
	}

	func previous(_ item: Self.Iterator.Element, loop: Bool = false) -> Self.Iterator
		.Element?
	{
		if let itemIndex = firstIndex(of: item) {
			let firstItem: Bool = (itemIndex == startIndex)
			if loop, firstItem {
				return last
			} else if firstItem {
				return nil
			} else {
				return self[index(before: itemIndex)]
			}
		}
		return nil
	}
}

public extension Array where Element: Identifiable {
	mutating func replace(_ element: Element) {
		if let index = firstIndex(where: { $0.id == element.id }) {
			remove(at: index)
			insert(element, at: index)
		} else {
			append(element)
		}
	}

	mutating func replace(elements values: [Element]) {
		for each in values {
			replace(each)
		}
	}
}
