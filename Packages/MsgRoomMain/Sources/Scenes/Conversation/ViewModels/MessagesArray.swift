//  DynamicDataSource.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 21/11/25.
//

import Database
import Services
import SwiftUI
import XUI

@MainActor
@Observable
final class MessagesArray: ViewReloadable {

	typealias Element = MsgCellViewModel
	typealias Index = Int

	var reloadID: Int = 0

	private var items: [Element]
	var array: [Element] { items }

	init(_ initialItems: [Element] = []) {
		self.items = initialItems
		trackItemsChanges()
	}

	var startIndex: Int { items.startIndex }
	var endIndex: Int { items.endIndex }
	var first: MsgCellViewModel? { items.first }
	var last: MsgCellViewModel? { items.last }
	var count: Int { items.count }
	var isEmpty: Bool { items.isEmpty }

	subscript(position: Int) -> Element {
		assert(items.indices.contains(position), "MessagesArray subscript out of range: \(position) not in \(items.indices)")
		return items[position]
	}

	// Safe access that won’t crash; returns nil if out of bounds.
	subscript(safe position: Int) -> Element? {
		items.indices.contains(position) ? items[position] : nil
	}

	func trackItemsChanges() {
		withObservationTracking {
			_ = items.count
		} onChange: { [weak self] in
			guard let self else { return }
			Task { @MainActor in
				layoutIfNeeded()
				trackItemsChanges()
			}
		}
	}
}

extension MessagesArray {
	func element(withID id: String) -> Element? {
		items.first(where: { $0.id == id })
	}
	func element(at index: Int) -> Element? {
		items.indices.contains(index) ? items[index] : nil
	}

	func index(of id: String) -> Int? {
		items.firstIndex(where: { $0.msg.uid == id })
	}
	func contains(withID id: String) -> Bool {
		items.contains(where: { $0.id == id })
	}
}

extension MessagesArray {

	func append(_ newElement: Element) {
		items.append(newElement)
	}

	func insert(_ newElement: Element, at index: Index) {
		items.insert(newElement, at: Swift.max(0, Swift.min(index, items.count)))
	}

	func removeAll(where shouldRemove: (Element) -> Bool) {
		items.removeAll(where: shouldRemove)
	}

	func removePrefix(_ count: Int) {
		guard count > 0 else { return }
		if count >= items.count {
			items.removeAll()
		} else {
			items.removeFirst(count)
		}
	}

	func removeSuffix(_ count: Int) {
		guard count > 0 else { return }
		if count >= items.count {
			items.removeAll()
		} else {
			items.removeLast(count)
		}
	}
}

extension MessagesArray {
	func takingPrefix(_ count: Int) -> Self {
		guard count > 0 else { return .init([]) }
		return .init(Array(items.prefix(count)))
	}

	func takingSuffix(_ count: Int) -> Self {
		guard count > 0 else { return .init([]) }
		return .init(Array(items.suffix(count)))
	}
}

extension MessagesArray {
	func insertionIndex(
		for newElement: Element,
		by keyPath: KeyPath<Element, some Comparable>
	) -> Index {
		items.insertionIndex(for: newElement, by: keyPath)
	}
}

extension MessagesArray {

	func neighbors(for index: Index) -> (previous: Element?, next: Element?) {
		let previous = self[safe: index - 1]
		let next = self[safe: index + 1]
		return (previous, next)
	}

	func update(
		_ message: Message,
		layoutProvider: (Message, Message?, Message?) -> MsgCellLayout
	) {
		guard let idx = index(of: message.uid),
			let model = element(at: idx)
		else { return }

		model.update(with: message)

		let (prev, next) = neighbors(for: idx)

		let newLayout = layoutProvider(model.msg, prev?.msg, next?.msg)
		model.update(layout: newLayout)

		if let prev {
			let prevPrev = self[safe: idx - 2]?.msg
			let prevLayout = layoutProvider(prev.msg, prevPrev, model.msg)
			prev.update(layout: prevLayout)
		}
		if let next {
			let nextNext = self[safe: idx + 2]?.msg
			let nextLayout = layoutProvider(next.msg, model.msg, nextNext)
			next.update(layout: nextLayout)
		}
	}
	func remove(
		_ message: Message,
		layoutProvider: (Message, Message?, Message?) -> MsgCellLayout
	) {
		guard let idx = index(of: message.uid) else {
			return
		}
		let prev = self[safe: idx - 1]
		let next = self[safe: idx + 1]
		items.remove(at: idx)
		if let prev {
			let newPrevPrev = self[safe: idx - 2]?.msg
			let prevLayout = layoutProvider(prev.msg, newPrevPrev, next?.msg)
			prev.update(layout: prevLayout)
		}
		if let next {
			let newNextNext = self[safe: (prev == nil ? idx + 1 : idx + 2)]?.msg
			let nextLayout = layoutProvider(next.msg, prev?.msg, newNextNext)
			next.update(layout: nextLayout)
		}
	}
}
