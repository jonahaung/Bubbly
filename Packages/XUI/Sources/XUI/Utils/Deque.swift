//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

@frozen
public struct Deque<Element>: RandomAccessCollection, MutableCollection, CustomStringConvertible {

    // MARK: - Storage

    @usableFromInline
    var buffer: [Element?]

    @usableFromInline
    var head: Int = 0

    public private(set) var count: Int = 0

    // MARK: - Init

    public init(_ capacity: Int = 16) {
        buffer = Array(repeating: nil, count: Swift.max(1, capacity))
    }

    public init<S: Sequence>(_ sequence: S) where S.Element == Element {
        let elements = Array(sequence)
        buffer = Array(repeating: nil, count: Swift.max(1, elements.count))
        for element in elements {
            enqueue(element)
        }
    }

    // MARK: - Collection

    public var startIndex: Int {
        0
    }

    public var endIndex: Int {
        count
    }

    public func index(after i: Int) -> Int {
        i + 1
    }

    public func index(before i: Int) -> Int {
        i - 1
    }

    public subscript(position: Int) -> Element {
        get {
            precondition(position >= 0 && position < count, "Index out of range")
            return buffer[physicalIndex(position)]!
        }
        set {
            precondition(position >= 0 && position < count, "Index out of range")
            buffer[physicalIndex(position)] = newValue
        }
    }

    // MARK: - Properties

    public var isEmpty: Bool {
        count == 0
    }

    public var capacity: Int {
        buffer.count
    }

    public var utilization: Double {
        Double(count) / Double(capacity)
    }

    public var front: Element? {
        isEmpty ? nil : buffer[head]
    }

    public var back: Element? {
        guard !isEmpty else { return nil }
        return buffer[physicalIndex(count - 1)]
    }

    // MARK: - Core Operations

    public mutating func enqueue(_ element: Element) {
        ensureCapacityForInsert()
        buffer[physicalIndex(count)] = element
        count += 1
    }

    public mutating func enqueueFront(_ element: Element) {
        ensureCapacityForInsert()
        head = previousIndex(head)
        buffer[head] = element
        count += 1
    }

    @discardableResult
    public mutating func dequeue() -> Element? {
        guard !isEmpty else { return nil }
        let element = buffer[head]
        buffer[head] = nil
        head = nextIndex(head)
        count -= 1
        return element
    }

    @discardableResult
    public mutating func dequeueBack() -> Element? {
        guard !isEmpty else { return nil }
        let index = physicalIndex(count - 1)
        let element = buffer[index]
        buffer[index] = nil
        count -= 1
        return element
    }

    public func peek() -> Element? {
        front
    }

    // MARK: - Utilities

    public mutating func removeAll(keepingCapacity: Bool = false) {
        if keepingCapacity {
            for i in 0..<buffer.count {
                buffer[i] = nil
            }
        } else {
            buffer = Array(repeating: nil, count: 16)
        }
        head = 0
        count = 0
    }

    public var description: String {
        "[" + map { "\($0)" }.joined(separator: ", ") + "]"
    }
}

// MARK: - Private Helpers

private extension Deque {

    @inline(__always)
    func nextIndex(_ i: Int) -> Int {
        (i + 1) % buffer.count
    }

    @inline(__always)
    func previousIndex(_ i: Int) -> Int {
        (i - 1 + buffer.count) % buffer.count
    }

    @inline(__always)
    func physicalIndex(_ logicalIndex: Int) -> Int {
        (head + logicalIndex) % buffer.count
    }

    mutating func ensureCapacityForInsert() {
        if count == buffer.count {
            resize()
        }
    }

    mutating func resize() {
        let newCapacity = buffer.count << 1
        var newBuffer = [Element?](repeating: nil, count: newCapacity)

        for i in 0..<count {
            newBuffer[i] = buffer[physicalIndex(i)]
        }

        buffer = newBuffer
        head = 0
    }
}
