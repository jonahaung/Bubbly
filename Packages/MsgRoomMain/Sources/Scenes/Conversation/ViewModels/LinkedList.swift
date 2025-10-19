//
//  LinkedList.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 19/10/25.
//

import Foundation

public struct LinkedList<Element>: Collection, ExpressibleByArrayLiteral, CustomStringConvertible {
	public final class Node {
		var value: Element
		var next: Node?
		weak var previous: Node?

		init(value: Element) {
			self.value = value
		}
	}

	final class Storage {
		var head: Node?
		init(head: Node? = nil) {
			self.head = head
		}

		func clone() -> Storage {
			guard let head else { return Storage() }
			let newHead = Node(value: head.value)
			var newNode = newHead
			var oldNode = head.next
			while let nextOld = oldNode {
				let nextNew = Node(value: nextOld.value)
				newNode.next = nextNew
				nextNew.previous = newNode
				newNode = nextNew
				oldNode = nextOld.next
			}
			return Storage(head: newHead)
		}
	}

	private var storage: Storage

	public init() {
		storage = Storage()
	}

	public init(array: [Element]) {
		self.init()
		array.forEach { append($0) }
	}

	public init(arrayLiteral elements: Element...) {
		self.init(array: elements)
	}

	private var head: Node? {
		get { storage.head }
		set { storage.head = newValue }
	}

	public var isEmpty: Bool { head == nil }

	public var count: Int {
		guard var node = head else { return 0 }
		var count = 1
		while let next = node.next {
			node = next
			count += 1
		}
		return count
	}

	public var first: Element? { head?.value }

	public var last: Element? {
		var node = head
		while let next = node?.next { node = next }
		return node?.value
	}

	private mutating func ensureUnique() {
		if !isKnownUniquelyReferenced(&storage) {
			storage = storage.clone()
		}
	}

	public func node(at index: Int) -> Node {
		precondition(index >= 0, "Index out of bounds")
		guard var node = head else { fatalError("Empty list") }
		if index == 0 { return node }
		for _ in 0..<index {
			guard let next = node.next else { fatalError("Index out of bounds") }
			node = next
		}
		return node
	}

	public subscript(index: Int) -> Element {
		get { node(at: index).value }
		set {
			ensureUnique()
			node(at: index).value = newValue
		}
	}

	public mutating func append(_ value: Element) {
		ensureUnique()
		let newNode = Node(value: value)
		if let head = head {
			var last = head
			while let next = last.next { last = next }
			last.next = newNode
			newNode.previous = last
		} else {
			head = newNode
		}
	}

	public mutating func insert(_ value: Element, at index: Int) {
		ensureUnique()
		let newNode = Node(value: value)
		if index == 0 {
			newNode.next = head
			head?.previous = newNode
			head = newNode
		} else {
			let prev = node(at: index - 1)
			let next = prev.next
			newNode.previous = prev
			newNode.next = next
			prev.next = newNode
			next?.previous = newNode
		}
	}

	@discardableResult
	public mutating func remove(at index: Int) -> Element {
		ensureUnique()
		let target = node(at: index)
		let prev = target.previous
		let next = target.next
		if let prev = prev {
			prev.next = next
		} else {
			head = next
		}
		next?.previous = prev
		return target.value
	}

	public mutating func removeAll() {
		ensureUnique()
		head = nil
	}

	public var description: String {
		var s = "["
		var node = head
		while let n = node {
			s += "\(n.value)"
			node = n.next
			if node != nil { s += ", " }
		}
		return s + "]"
	}

	public struct Index: Comparable {
		fileprivate let node: Node?
		fileprivate let tag: Int
		public static func == (lhs: Index, rhs: Index) -> Bool { lhs.tag == rhs.tag }
		public static func < (lhs: Index, rhs: Index) -> Bool { lhs.tag < rhs.tag }
	}

	public var startIndex: Index { Index(node: head, tag: 0) }

	public var endIndex: Index {
		Index(node: nil, tag: count)
	}

	public subscript(position: Index) -> Element {
		position.node!.value
	}

	public func index(after idx: Index) -> Index {
		Index(node: idx.node?.next, tag: idx.tag + 1)
	}
	@discardableResult
	public mutating func removeFirst(_ k: Int) -> [Element] {
		ensureUnique()
		guard k > 0, var node = head else { return [] }

		var removed: [Element] = []
		var remaining = k
		while remaining > 0 {
			removed.append(node.value)
			if let next = node.next {
				node = next
			} else {
				head = nil
				return removed
			}
			remaining -= 1
		}

		head = node
		head?.previous = nil
		return removed
	}
	@discardableResult
	public mutating func removeLast(_ k: Int) -> [Element] {
		ensureUnique()
		guard k > 0, var node = head else { return [] }

		// Find the tail
		while let next = node.next { node = next }

		var removed: [Element] = []
		var remaining = k
		while remaining > 0 {
			removed.insert(node.value, at: 0)
			if let prev = node.previous {
				node = prev
			} else {
				head = nil
				return removed
			}
			remaining -= 1
		}

		node.next = nil
		return removed
	}
}

public extension LinkedList {
	func insertionIndex(
		for newElement: Element,
		by keyPath: KeyPath<Element, Date>
	) -> Int {
		var low = 0
		var high = count

		let newValue = newElement[keyPath: keyPath]

		while low < high {
			let mid = (low + high) / 2
			if self[mid][keyPath: keyPath] < newValue {
				low = mid + 1
			} else {
				high = mid
			}
		}
		return low
	}
}

public extension LinkedList {
	// MARK: - Non-mutating: Removing

	func removingPrefix(_ count: Int) -> Self {
		guard count > 0 else { return self }
		return .init(array: Array(dropFirst(count)))
	}

	func removingSuffix(_ count: Int) -> Self {
		guard count > 0 else { return self }
		return .init(array: Array(dropLast(count)))
	}

	// MARK: - Non-mutating: Taking

	func takingPrefix(_ count: Int) -> [Element] {
		guard count > 0 else { return [] }
		return Array(prefix(count))
	}

	func takingSuffix(_ count: Int) -> [Element] {
		guard count > 0 else { return [] }
		return Array(suffix(count))
	}

	// MARK: - Non-mutating: Safe Slice

	// Adjust signature to use Index instead of Int
	func safeSlice(_ range: Range<Index>) -> [Element] {
		let lower = Swift.max(range.lowerBound, startIndex)
		let upper = Swift.min(range.upperBound, endIndex)
		guard lower < upper else { return [] }
		return Array(self[lower..<upper])
	}

	// MARK: - Mutating

	mutating func removePrefix(_ count: Int) {
		guard count > 0 else { return }
		if count >= self.count {
			removeAll()
		} else {
			removeFirst(count)
		}
	}

	mutating func removeSuffix(_ count: Int) {
		guard count > 0 else { return }
		if count >= self.count {
			removeAll()
		} else {
			removeLast(count)
		}
	}
}
