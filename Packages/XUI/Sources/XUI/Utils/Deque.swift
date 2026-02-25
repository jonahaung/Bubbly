import Foundation

/// A high-performance FIFO queue backed by a circular buffer.
/// Enqueue adds elements to the back; dequeue removes from the front.
@frozen
public struct Deque<Element>: Collection, Sequence, CustomStringConvertible {
	// MARK: - Storage

	private var array: [Element?]
	private var head: Int = 0
	public private(set) var count: Int = 0

	// MARK: - Initialization

	/// Creates an empty queue with an optional initial capacity.
	public init(_ capacity: Int = 10) {
		array = Array(repeating: nil, count: Swift.max(1, capacity))
	}

	/// Creates a queue from a sequence of elements.
	public init(_ sequence: some Sequence<Element>) {
		let elements = Array(sequence)
		array = Array(repeating: nil, count: Swift.max(1, elements.count))
		for e in elements {
			enqueue(e)
		}
	}

	// MARK: - Properties

	public var isFull: Bool {
		count == array.count
	}

	public var capacity: Int {
		array.count
	}

	public var utilization: Double {
		Double(count) / Double(capacity)
	}

	public var front: Element? {
		peek()
	}

	public var back: Element? {
		guard !isEmpty else { return nil }
		let tailIndex = (head + count - 1) % array.count
		return array[tailIndex]
	}

	// MARK: - Indexing (Collection)

	public var startIndex: Int {
		0
	}

	public var endIndex: Int {
		count
	}

	public func index(after i: Int) -> Int {
		i + 1
	}

	public subscript(position: Int) -> Element {
		precondition(position >= 0 && position < count, "Index out of range")
		let index = (head + position) % array.count
		return array[index]! // Safe after precondition check
	}

	// MARK: - Description

	public var description: String {
		"[" + map { "\($0)" }.joined(separator: ", ") + "]"
	}

	// MARK: - Internal Helpers

	@inline(__always)
	private func nextIndex(_ i: Int) -> Int {
		(i + 1) % array.count
	}

	// MARK: - Resizing

	private mutating func resize() {
		let newSize = array.count * 2
		var newArray = [Element?](repeating: nil, count: newSize)

		let rightCount = Swift.min(array.count - head, count)
		newArray[0 ..< rightCount] = array[head ..< head + rightCount]
		if count > rightCount {
			newArray[rightCount ..< count] = array[0 ..< count - rightCount]
		}

		head = 0
		array = newArray
	}

	// MARK: - Core Operations

	/// Adds an element to the back of the queue.
	public mutating func enqueue(_ element: Element) {
		if isFull { resize() }
		let tailIndex = (head + count) % array.count
		array[tailIndex] = element
		count += 1
	}
	/// Adds an element to the front of the deque.
	public mutating func enqueueFront(_ element: Element) {
		if isFull { resize() }

		// Move head backward (circularly)
		head = (head - 1 + array.count) % array.count
		array[head] = element
		count += 1
	}
	/// Removes and returns the element at the front of the queue.
	@discardableResult
	public mutating func dequeue() -> Element? {
		guard !isEmpty else { return nil }
		let element = array[head]
		array[head] = nil
		head = nextIndex(head)
		count -= 1
		return element
	}

	/// Returns the front element without removing it.
	public func peek() -> Element? {
		isEmpty ? nil : array[head]
	}

	// MARK: - Utility

	/// Removes all elements from the queue.
	public mutating func removeAll(keepingCapacity: Bool = false) {
		if keepingCapacity {
			array = Array(repeating: nil, count: array.count)
		} else {
			array = Array(repeating: nil, count: Swift.max(1, array.count / 2))
		}
		head = 0
		count = 0
	}
}
