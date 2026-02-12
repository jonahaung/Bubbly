//
//  Collection+.swift
//
//
//  Created by Aung Ko Min on 10/6/23.
//

import Foundation

/// Array
extension Array where Element: Hashable {
	public func uniqued() -> [Element] {
		var seen = Set<Element>()
		return filter { seen.insert($0).inserted }
	}
}

extension Collection where Indices.Iterator.Element == Index {
	public subscript(safe index: Index) -> Iterator.Element? {
		(startIndex <= index && index < endIndex) ? self[index] : nil
	}
}

extension Array {
	public mutating func shuffle() {
		if count == 0 {
			return
		}

		for index in 0..<(count - 1) {
			let randomIndex = Int.random(in: index..<count)
			if randomIndex != index {
				swapAt(index, randomIndex)
			}
		}
	}

	public func shuffled() -> [Element] {
		var list = self
		list.shuffle()

		return list
	}

	public func removeDuplicates(by predicate: (Element, Element) -> Bool) -> Self {
		var result = [Element]()
		for value in self where result.filter({ predicate($0, value) }).isEmpty {
			result.append(value)
		}
		return result
	}

	public func removeDuplicates(by keyPath: KeyPath<Element, String>) -> Self {
		removeDuplicates(by: { $0[keyPath: keyPath] == $1[keyPath: keyPath] })
	}

	public func removeDuplicates() -> Self where Element: Equatable {
		removeDuplicates(by: ==)
	}
}

extension Array {
	public func groupByKey<Key: Hashable>(keyPath: KeyPath<Element, Key>) -> [Key: [Element]] {
		Dictionary(grouping: self, by: { $0[keyPath: keyPath] })
	}
}

extension BidirectionalCollection where Iterator.Element: Equatable {
	public func nextElement(_ item: Self.Iterator.Element, loop: Bool = false) -> Self.Iterator
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

	public func previous(_ item: Self.Iterator.Element, loop: Bool = false) -> Self.Iterator
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

extension Array where Element: Identifiable {
	public mutating func replace(_ element: Element) {
		if let index = firstIndex(where: { $0.id == element.id }) {
			remove(at: index)
			insert(element, at: index)
		} else {
			append(element)
		}
	}

	public mutating func replace(elements values: [Element]) {
		for each in values {
			replace(each)
		}
	}
}
