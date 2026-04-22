//  IdentifiedArray.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Foundation

public struct IdentifiedArray<ID: Hashable, Element>: Sequence {

    public init(id: KeyPath<Element, ID>) {
        idKeyPath = id
        elements = []
        indexesByID = [:]
    }

    public init(_ elements: [Element], id: KeyPath<Element, ID>) {
        idKeyPath = id
        self.elements = elements
        indexesByID = [:]
        rebuildIndexes()
    }

    // MARK: Public

    public var count: Int {
        elements.count
    }

    public var isEmpty: Bool {
        elements.isEmpty
    }

    public var first: Element? {
        elements.first
    }

    public var last: Element? {
        elements.last
    }

    public var indices: Range<Int> {
        elements.indices
    }

    public subscript(index: Int) -> Element {
        get { elements[index] }
        set {
            elements[index] = newValue
            rebuildIndexes()
        }
    }

    public subscript(range: Range<Int>) -> ArraySlice<Element> {
        elements[range]
    }

    public subscript(id id: ID) -> Element? {
        guard let index = indexesByID[id] else {
            return nil
        }

        return elements[index]
    }

    public func index(id: ID) -> Int? {
        indexesByID[id]
    }

    public mutating func insert(_ element: Element, at index: Int) {
        elements.insert(element, at: index)
        rebuildIndexes()
    }

    public mutating func insert(_ newElements: [Element], at index: Int) {
        guard !newElements.isEmpty else {
            return
        }

        elements.insert(contentsOf: newElements, at: index)
        rebuildIndexes()
    }

    public mutating func append(_ element: Element) {
        elements.append(element)
        indexesByID[element[keyPath: idKeyPath]] = elements.count - 1
    }

    public mutating func append(_ newElements: [Element]) {
        guard !newElements.isEmpty else {
            return
        }

        let startIndex = elements.count
        elements.append(contentsOf: newElements)
        indexesByID.reserveCapacity(elements.count)
        for (offset, element) in newElements.enumerated() {
            indexesByID[element[keyPath: idKeyPath]] = startIndex + offset
        }
    }

    public mutating func remove(id: ID) {
        guard let index = indexesByID[id] else {
            return
        }

        elements.remove(at: index)
        rebuildIndexes()
    }

    public mutating func removeSubrange(_ bounds: Range<Int>) {
        elements.removeSubrange(bounds)
        rebuildIndexes()
    }

    public mutating func removeAll(keepingCapacity keepCapacity: Bool) {
        elements.removeAll(keepingCapacity: keepCapacity)
        indexesByID.removeAll(keepingCapacity: keepCapacity)
    }

    public func makeIterator() -> IndexingIterator<[Element]> {
        elements.makeIterator()
    }

    private let idKeyPath: KeyPath<Element, ID>
    private var elements: [Element]
    private var indexesByID: [ID: Int]

    private mutating func rebuildIndexes() {
        indexesByID.removeAll(keepingCapacity: true)
        indexesByID.reserveCapacity(elements.count)
        for (index, element) in elements.enumerated() {
            indexesByID[element[keyPath: idKeyPath]] = index
        }
    }
}
