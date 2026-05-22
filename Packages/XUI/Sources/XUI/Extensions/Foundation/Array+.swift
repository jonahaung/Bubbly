//  Array+.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

extension Array {
    @inlinable
    public func insertionIndex(
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

extension Array {
    public func random() -> Element {
        randomElement()!
    }
}

extension Array {
    @inlinable
    public var enumerated: [(index: Int, element: Element)] {
        self.enumerated().map { (index: $0.offset, element: $0.element) }
    }
}

extension Array where Element: Identifiable {
    @inlinable
    public func elementsAround(id: Element.ID, radius: Int) -> [Element]? {
        guard let index = firstIndex(where: { $0.id == id }) else {
            return nil
        }
        let safeRadius = Swift.max(0, radius)
        let lowerBound = Swift.max(0, index - safeRadius)
        let upperBound = Swift.min(count - 1, index + safeRadius)
        return Array(self[lowerBound...upperBound])
    }
}

extension Array where Element: Identifiable, Element.ID: Hashable {
    @inlinable
    public func duplicates() -> [Element] {
        var seen = Set<Element.ID>()
        var duplicates = [Element]()
        duplicates.reserveCapacity(count / 2)

        for item in self where !seen.insert(item.id).inserted {
            duplicates.append(item)
        }

        return duplicates
    }
}

extension Array {
    @inlinable
    public var middleElement: Element? {
        guard !isEmpty else { return nil }
        return self[(count - 1) / 2]
    }
}

extension Array where Element: Hashable {
    @inlinable
    public mutating func appendUnique(_ newElement: Element) {
        if !contains(newElement) { append(newElement) }
    }

    @inlinable
    public mutating func appendUnique(
        contentsOf newElements: some Sequence<Element>
    ) {
        var seen = Set(self)
        for element in newElements where seen.insert(element).inserted {
            append(element)
        }
    }
}
extension Array where Element: Identifiable {
    @inlinable
    public func index(of id: Element.ID) -> Int? {
        firstIndex(where: { $0.id == id })
    }
}

extension Array {
    // MARK: - Non-mutating: Removing

    @inlinable
    public func removingPrefix(_ count: Int) -> [Element] {
        guard count > 0 else { return self }
        return Array(dropFirst(count))
    }

    @inlinable
    public func removingSuffix(_ count: Int) -> [Element] {
        guard count > 0 else { return self }
        return Array(dropLast(count))
    }

    // MARK: - Non-mutating: Taking

    @inlinable
    public func takingPrefix(_ count: Int) -> [Element] {
        guard count > 0 else { return [] }
        return Array(prefix(count))
    }

    @inlinable
    public func takingSuffix(_ count: Int) -> [Element] {
        guard count > 0 else { return [] }
        return Array(suffix(count))
    }
}
