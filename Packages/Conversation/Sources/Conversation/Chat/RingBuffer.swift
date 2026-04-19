//
//  RingBuffer.swift
//  Conversation
//
//  Created by Aung Ko Min on 18/4/26.
//

import Foundation

@frozen
public struct RingBuffer<Element> {

	private var buffer: ContiguousArray<Element?>
	private var head: Int = 0
	private(set) var count: Int = 0

	public init(capacity: Int = 1024) {
		buffer = ContiguousArray(repeating: nil, count: max(1, capacity))
	}

	public var capacity: Int { buffer.count }

	// MARK: - Indexing

	private func index(_ offset: Int) -> Int {
		(head + offset) % capacity
	}

	public subscript(i: Int) -> Element {
		buffer[index(i)]!
	}

	// MARK: - Mutations

	public mutating func append(_ element: Element) {
		ensureCapacity(count + 1)
		buffer[index(count)] = element
		count += 1
	}

	public mutating func prepend(_ element: Element) {
		ensureCapacity(count + 1)
		head = (head - 1 + capacity) % capacity
		buffer[head] = element
		count += 1
	}

	public mutating func removeFirst() -> Element? {
		guard count > 0 else { return nil }
		let value = buffer[head]
		buffer[head] = nil
		head = (head + 1) % capacity
		count -= 1
		return value
	}

	public mutating func removeLast() -> Element? {
		guard count > 0 else { return nil }
		let tailIndex = index(count - 1)
		let value = buffer[tailIndex]
		buffer[tailIndex] = nil
		count -= 1
		return value
	}
}
private extension RingBuffer {

    mutating func ensureCapacity(_ needed: Int) {
        guard needed > capacity else { return }

        let newCapacity = capacity * 2
        var newBuffer = ContiguousArray<Element?>(
            repeating: nil,
            count: newCapacity
        )

        for i in 0..<count {
            newBuffer[i] = self[i]
        }

        buffer = newBuffer
        head = 0
    }
}
