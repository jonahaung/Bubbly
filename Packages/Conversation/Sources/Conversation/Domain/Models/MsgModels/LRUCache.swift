//
//  LRUCache.swift
//  Conversation
//
//  Created by Aung Ko Min on 26/2/26.
//

import Foundation

final class LRUCache<Key: Hashable, Value> {

	private final class Node {
		let key: Key
		var value: Value
		var prev: Node?
		var next: Node?

		init(key: Key, value: Value) {
			self.key = key
			self.value = value
		}
	}

	private let capacity: Int
	private var dict: [Key: Node] = [:]
	private var head: Node?
	private var tail: Node?

	init(capacity: Int) {
		self.capacity = max(1, capacity)
	}

	func get(_ key: Key) -> Value? {
		guard let node = dict[key] else { return nil }
		moveToTail(node)
		return node.value
	}

	func set(_ key: Key, value: Value) {
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

	func remove(_ key: Key) {
		guard let node = dict[key] else { return }
		remove(node)
		dict[key] = nil
	}

	func removeAll() {
		dict.removeAll()
		head = nil
		tail = nil
	}

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
		dict[head.key] = nil
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
