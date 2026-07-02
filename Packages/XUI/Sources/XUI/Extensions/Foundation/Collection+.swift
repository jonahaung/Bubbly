//  Collection+.swift
//
//  Copyright © 2025 Aung Ko Min.
//

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
