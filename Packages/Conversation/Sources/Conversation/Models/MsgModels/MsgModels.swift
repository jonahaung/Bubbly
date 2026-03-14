//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Dispatch
import Foundation
import Services
import SwiftUI
import XUI

@MainActor
public final class MsgModels {

	private var storage = [MsgCellViewModel]()
	private let modelCache = LRUCache<String, MsgCellViewModel>()
	private let layoutCache = LRUCache<String, MsgCellLayout>()
	private let bubbleFactory = BubbleFactory()

	init(_ msgs: [Message] = []) {
		storage = msgs.map({ msg in
			model(for: msg)
		})
		evictLayoutsIfNeeded()
	}

	deinit {
		modelCache.removeAll()
		layoutCache.removeAll()
		log("deinit")
	}
}

extension MsgModels {
	public var count: Int {
		storage.count
	}

	public var first: MsgCellViewModel? {
		storage.first
	}

	public var last: MsgCellViewModel? {
		storage.last
	}

	public var isEmpty: Bool {
		storage.isEmpty
	}

	public var renderedModels: [MsgCellViewModel] {
		storage
	}

	public func contains(withID id: String) -> Bool {
		storage.contains(where: { $0.id == id })
	}

	public func index(of id: String) -> Int? {
		storage.firstIndex(where: { $0.id == id })
	}

	public subscript(position: Int) -> MsgCellViewModel? {
		storage.indices.contains(position) ? storage[position] : nil
	}

	public subscript(safe position: Int) -> MsgCellViewModel? {
		storage.indices.contains(position) ? storage[position] : nil
	}

	public func element(withID id: String) -> MsgCellViewModel? {
		storage.first(where: { $0.id == id }) ?? modelCache.get(id)
	}

	public func msgs() -> [Message] {
		var result: [Message] = []
		result.reserveCapacity(storage.count)
		for model in storage {
			result.append(model.msg)
		}
		return result
	}
}

extension MsgModels {

	public func didChangeVisibility(for id: String, isVisible: Bool) {
		element(withID: id)?.setVisibility(isVisible)
	}

	public func didChangeSelection(_ selectedMsg: SelectedMsg?, for id: String) {
		element(withID: id)?.update(selectedMsg: selectedMsg)
	}

	public func cached(for id: String) -> MsgCellViewModel? {
		modelCache.get(id)
	}

	public func model(for msg: Message) -> MsgCellViewModel {
		if let cached = modelCache.get(msg.uid) { return cached }
		let model = MsgCellViewModel(msg)
		modelCache.set(msg.uid, value: model)
		return model
	}

	public func set(msgs: [Message]) {
		storage = msgs.map({ msg in
			model(for: msg)
		})
		evictLayoutsIfNeeded()
	}

	public func insert(msg: Message) {
		let index = insertionIndex(for: msg)
		let model = model(for: msg)
		storage.insert(model, at: index)
		invalidateLayoutsForUpdate(at: index)
	}

	public func update(msg: Message) {
		modelCache.get(msg.uid)?.update(with: msg)
	}

	public func remove(msg: Message) {
		guard let removedIndex = index(of: msg.uid) else { return }
		storage.removeAll(where: { $0.id == msg.id })
		layoutCache.remove(msg.uid)
		invalidateLayoutsAround(index: removedIndex)
	}

	public func prepend(_ msgs: [Message]) {
		storage.insert(contentsOf: msgs.map { model(for: $0) }, at: 0)
		evictLayoutsIfNeeded()
	}
	public func append(_ msgs: [Message]) {
		storage.append(contentsOf: msgs.map { model(for: $0) })
		evictLayoutsIfNeeded()
	}
	public func retainOldest(_ limit: Int) {
		guard limit >= 0 else { return }
		guard storage.count > limit else { return }
		storage.removeSubrange(limit..<storage.count)
	}

	public func retainNewest(_ limit: Int) {
		guard limit >= 0 else { return }
		guard storage.count > limit else { return }
		let removeCount = storage.count - limit
		storage.removeSubrange(0..<removeCount)
	}
}

extension MsgModels {
	private func insertionIndex(for msg: Message) -> Int {
		msgs().insertionIndex(for: msg, by: \.date)
//		var low = 0
//		var high = storage.count
//		while low < high {
//			let mid = (low + high) / 2
//			if precedes(storage[mid].msg, msg) {
//				low = mid + 1
//			} else {
//				high = mid
//			}
//		}
//		return low
	}

	private func precedes(_ lhs: Message, _ rhs: Message) -> Bool {
		if lhs.date != rhs.date {
			return lhs.date < rhs.date
		}
		return lhs.uid < rhs.uid
	}

	private func invalidateLayoutsForUpdate(at index: Int) {
		invalidateLayoutsAround(index: index)
		let lower = max(index - 1, 0)
		let upper = min(index + 2, storage.count)
		if lower < upper {
			ensureLayouts(in: lower..<upper)
		}
	}

	private func invalidateLayoutsForMove(from oldIndex: Int, to newIndex: Int) {
		invalidateLayoutsAround(index: oldIndex)
		invalidateLayoutsAround(index: newIndex)
		let lower = max(min(oldIndex, newIndex) - 1, 0)
		let upper = min(max(oldIndex, newIndex) + 2, storage.count)
		if lower < upper {
			ensureLayouts(in: lower..<upper)
		}
	}

	private func invalidateLayoutsAround(index: Int) {
		guard !storage.isEmpty else { return }
		let lower = max(0, index - 1)
		let upper = min(storage.count - 1, index + 1)
		if lower > upper { return }
		for index in lower...upper {
			layoutCache.remove(storage[index].id)
		}
	}

	private func layout(for id: String) {
		guard let index = index(of: id) else { return }
		if let cached = layoutCache.get(id) {
			if storage[index].state.layout.isEmpty {
				storage[index].update(layout: cached)
			}
			return
		}

		let prevMsg = index > 0 ? storage[index - 1].msg : nil
		let nextMsg = index + 1 < storage.count ? storage[index + 1].msg : nil
		let style = bubbleFactory.style(for: storage[index].msg, previous: prevMsg, next: nextMsg)
		layoutCache.set(id, value: style)
		storage[index].update(layout: style)
	}

	private func ensureLayouts(in range: Range<Int>) {
		guard !range.isEmpty else { return }
		for index in range {
			layout(for: storage[index].id)
		}
	}

	private func evictLayoutsIfNeeded() {
		for each in storage {
			layout(for: each.id)
		}
	}
}
