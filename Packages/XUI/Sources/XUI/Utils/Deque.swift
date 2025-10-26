//
//  Deque.swift
//  XUI
//
//  Created by Aung Ko Min on 19/10/25.
//

import Foundation

public struct Deque<Element>: Collection, Sequence, CustomStringConvertible {

	// MARK: - Storage

	private var array: [Element?]
	private var head: Int = 0
	public private(set) var count: Int = 0

	// MARK: - Initialization

	public init(_ capacity: Int = 10) {
		array = Array(repeating: nil, count: Swift.max(1, capacity))
	}

	public var isEmpty: Bool { count == 0 }
	public var isFull: Bool { count == array.count }

	public var capacity: Int { array.count }
	public var utilization: Double { Double(count) / Double(capacity) }

	// MARK: - Indexing (for Collection)

	public var startIndex: Int { 0 }
	public var endIndex: Int { count }

	public func index(after i: Int) -> Int { i + 1 }

	public subscript(position: Int) -> Element {
		let index = (head + position) % array.count
		return array[index]! // Valid because position < count
	}

	// MARK: - Printing

	public var description: String {
		return "[" + self.map({ "\($0)" }).joined(separator: ", ") + "]"
	}

	// MARK: - Helper (circular movement)

	@inline(__always) private func nextIndex(_ i: Int) -> Int {
		(i + 1) % array.count
	}

	@inline(__always) private func prevIndex(_ i: Int) -> Int {
		(i - 1 + array.count) % array.count
	}

	// Resize buffer when full
	private mutating func resize() {
		let newSize = array.count * 2
		var newArray = [Element?](repeating: nil, count: newSize)

		for i in 0..<count {
			newArray[i] = self[i]
		}
		head = 0
		array = newArray
	}

	// MARK: - Core Operations

	public mutating func enqueue(_ element: Element) {
		if isFull { resize() }
		let tailIndex = (head + count) % array.count
		array[tailIndex] = element
		count += 1
	}

	public mutating func enqueueFront(_ element: Element) {
		if isFull { resize() }
		head = prevIndex(head)
		array[head] = element
		count += 1
	}

	@discardableResult
	public mutating func dequeue() -> Element? {
		guard !isEmpty else { return nil }
		let element = array[head]
		array[head] = nil
		head = nextIndex(head)
		count -= 1
		return element
	}

	@discardableResult
	public mutating func dequeueBack() -> Element? {
		guard !isEmpty else { return nil }
		let tailIndex = (head + count - 1) % array.count
		let element = array[tailIndex]
		array[tailIndex] = nil
		count -= 1
		return element
	}

	// MARK: - Peek

	public func peekFront() -> Element? { isEmpty ? nil : array[head] }

	public func peekBack() -> Element? {
		isEmpty ? nil : array[(head + count - 1) % array.count]
	}

	// MARK: - Utility

	public mutating func removeAll(keepingCapacity: Bool = false) {
		if keepingCapacity {
			array = Array(repeating: nil, count: array.count)
		} else {
			array = Array(repeating: nil, count: 1)
		}
		head = 0
		count = 0
	}
}
