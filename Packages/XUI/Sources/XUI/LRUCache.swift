//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class LRUCache<Key: Hashable, Value>: @unchecked Sendable {

	// MARK: Node

	private final class Node: @unchecked Sendable {
		let key: Key
		var value: Value
		var prev: Node?
		var next: Node?

		init(key: Key, value: Value) {
			self.key = key
			self.value = value
		}
	}

	// MARK: Properties

	private let capacity: Int
	private var dict: [Key: Node] = [:]

	private var head: Node?
	private var tail: Node?

	private let lock = NSLock()

	// MARK: Init

	public init(capacity: Int = 500) {
		self.capacity = max(1, capacity)
	}

	deinit {
		removeAll()
	}

	// MARK: Public API

	public var count: Int {
		lock.lock()
		defer { lock.unlock() }
		return dict.count
	}

	public func get(_ key: Key) -> Value? {
		lock.lock()
		defer { lock.unlock() }

		guard let node = dict[key] else { return nil }

		moveToTail(node)

		return node.value
	}

	public func set(_ key: Key, value: Value) {
		lock.lock()
		defer { lock.unlock() }

		if let node = dict[key] {
			node.value = value
			moveToTail(node)
			return
		}

		let node = Node(key: key, value: value)

		dict[key] = node
		append(node)

		if dict.count > capacity {
			removeHead()
		}
	}

	public func remove(_ key: Key) {
		lock.lock()
		defer { lock.unlock() }

		guard let node = dict[key] else { return }

		remove(node)

		dict.removeValue(forKey: key)
	}

	public func removeAll() {
		lock.lock()
		defer { lock.unlock() }

		dict.removeAll()

		head = nil
		tail = nil
	}

	// MARK: Private Helpers

	private func append(_ node: Node) {
		if let tail {
			tail.next = node
			node.prev = tail
			self.tail = node
		} else {
			head = node
			tail = node
		}
	}

	private func moveToTail(_ node: Node) {
		guard tail !== node else { return }

		remove(node)

		append(node)
	}

	private func removeHead() {
		guard let head else { return }

		remove(head)

		dict.removeValue(forKey: head.key)
	}

	private func remove(_ node: Node) {
		let prev = node.prev
		let next = node.next

		if let prev {
			prev.next = next
		} else {
			head = next
		}

		if let next {
			next.prev = prev
		} else {
			tail = prev
		}

		node.prev = nil
		node.next = nil
	}
}
