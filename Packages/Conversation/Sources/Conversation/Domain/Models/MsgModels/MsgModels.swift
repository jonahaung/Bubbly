import Database
import Dispatch
import Foundation
import Services
import SwiftUI
import XUI

@MainActor
@Observable
public final class MsgModels {
	public typealias MsgID = Message.UID

	public struct ScrollCompensation: Sendable, Equatable {
		public let anchorID: MsgID?
		public let insertedBeforeAnchor: Int
	}

	private enum MergeMode {
		case general
		case prepend(anchorID: MsgID?)
	}

	private struct UpsertResult {
		let index: Int
		let inserted: Bool
	}

	private enum MutationKind {
		case set
		case prepend
		case insert
		case update
		case remove
		case jump
	}

	private var storage = IdentifiedArray<MsgID, MsgCellViewModel>(id: \MsgCellViewModel.id)
	@ObservationIgnored private var modelCache = [MsgID: MsgCellViewModel]()
	@ObservationIgnored private var layoutCache = [MsgID: MsgCellLayout]()
	@ObservationIgnored private var bubbleFactory = BubbleFactory()
	@ObservationIgnored private let maxLayoutCacheCount: Int

	private(set) var viewportWindow: Range<Int> = 0 ..< 0
	private(set) var scrollAnchor: MsgID?

	@ObservationIgnored private let windowing: MsgViewportWindowing

	init(_ msgs: [Message] = []) {
		let resolvedWindowSize = Self.resolveWindowSize()
		windowing = .init(
			windowSize: resolvedWindowSize,
			edgeThreshold: max(4, min(24, resolvedWindowSize / 5)),
			lead: max(8, min(60, resolvedWindowSize / 3))
		)
		maxLayoutCacheCount = max(300, resolvedWindowSize * 4)
		set(msgs: msgs, forceReset: true)
	}
}

public extension MsgModels {
	var count: Int {
		storage.count
	}

	var first: MsgCellViewModel? {
		storage.first
	}

	var last: MsgCellViewModel? {
		storage.last
	}

	var isEmpty: Bool {
		storage.isEmpty
	}

	var renderedModels: [MsgCellViewModel] {
		let range = normalizedWindow()
		guard !range.isEmpty else { return [] }
		ensureLayouts(in: range)
		return Array(storage[range])
	}

	func contains(withID id: MsgID) -> Bool {
		storage[id: id] != nil
	}

	func index(of id: MsgID) -> Int? {
		storage.index(id: id)
	}

	subscript(position: Int) -> MsgCellViewModel? {
		storage.indices.contains(position) ? storage[position] : nil
	}

	subscript(safe position: Int) -> MsgCellViewModel? {
		storage.indices.contains(position) ? storage[position] : nil
	}

	func element(withID id: MsgID) -> MsgCellViewModel? {
		storage[id: id] ?? modelCache[id]
	}

	func msgs() -> [Message] {
		var result: [Message] = []
		result.reserveCapacity(storage.count)
		for model in storage {
			result.append(model.msg)
		}
		return result
	}
}

public extension MsgModels {
	func cached(for id: MsgID) -> MsgCellViewModel? {
		modelCache[id]
	}

	func model(for msg: Message) -> MsgCellViewModel {
		if let cached = modelCache[msg.uid] { return cached }
		let model = MsgCellViewModel(msg)
		modelCache[msg.uid] = model
		return model
	}

	func style(for id: MsgID) -> MsgCellLayout? {
		layout(for: id)
	}

	func ensureLayout(for id: MsgID) {
		_ = layout(for: id)
	}

	func didChangeVisibility(for id: MsgID, isVisible: Bool) {
		guard isVisible, let index = storage.index(id: id) else { return }
		scrollAnchor = id
		adjustViewport(around: index)
	}

	@discardableResult
	func jump(to id: MsgID) -> Bool {
		guard let index = storage.index(id: id) else { return false }
		scrollAnchor = id
		viewportWindow = windowing.centeredWindow(on: index, totalCount: storage.count)
		ensureLayouts(in: viewportWindow)
		return true
	}

	func set(msgs: [Message], forceReset: Bool) {
		merge(msgs: msgs, forceReset: forceReset, mode: .general)
	}

	@discardableResult
	func prepend(msgs: [Message], preserveAnchor anchorID: MsgID?) -> ScrollCompensation {
		let anchor = anchorID ?? scrollAnchor
		let beforeIndex = anchor.flatMap { storage.index(id: $0) }
		merge(msgs: msgs, forceReset: false, mode: .prepend(anchorID: anchorID))
		let afterIndex = anchor.flatMap { storage.index(id: $0) }
		let insertedBeforeAnchor = max(0, (afterIndex ?? 0) - (beforeIndex ?? afterIndex ?? 0))
		return .init(anchorID: anchor, insertedBeforeAnchor: insertedBeforeAnchor)
	}

	func insert(msg: Message) {
		withBatchUpdate {
			let result = upsert(msg)
			if let index = storage.index(id: msg.uid) {
				adjustViewportForMutation(at: index, inserted: result.inserted)
			}
		}
	}

	func update(msg: Message) {
		withBatchUpdate {
			_ = upsert(msg)
		}
	}

	func remove(msg: Message) {
		withBatchUpdate {
			guard let removedIndex = storage.index(id: msg.uid) else { return }
			storage.remove(id: msg.uid)
			layoutCache[msg.uid] = nil
			invalidateLayoutsAround(index: removedIndex)
			adjustViewportForRemoval(removedID: msg.uid)
		}
	}

	func retainOldest(_ limit: Int) {
		guard limit >= 0 else { return }
		withBatchUpdate {
			guard storage.count > limit else {
				ensureViewportBounds()
				return
			}
			let removedIDs = Array(storage[limit ..< storage.count].map(\.id))
			storage.removeSubrange(limit ..< storage.count)
			for id in removedIDs {
				layoutCache[id] = nil
			}
			ensureViewportBounds()
		}
	}

	func retainNewest(_ limit: Int) {
		guard limit >= 0 else { return }
		withBatchUpdate {
			guard storage.count > limit else {
				ensureViewportBounds()
				return
			}
			let removeCount = storage.count - limit
			let removedIDs = Array(storage[0 ..< removeCount].map(\.id))
			storage.removeSubrange(0 ..< removeCount)
			for id in removedIDs {
				layoutCache[id] = nil
			}
			ensureViewportBounds()
		}
	}
}

private extension MsgModels {
	private func merge(msgs: [Message], forceReset: Bool, mode: MergeMode) {
		guard !msgs.isEmpty || forceReset else { return }
		withBatchUpdate {
			if forceReset {
				storage.removeAll(keepingCapacity: true)
				layoutCache.removeAll(keepingCapacity: true)
			}

			let sortedMsgs = msgs.sorted(by: precedes)
			for msg in sortedMsgs {
				_ = upsert(msg)
			}

			if storage.isEmpty {
				viewportWindow = 0 ..< 0
				scrollAnchor = nil
				return
			}

			switch mode {
			case .general:
				if let anchor = scrollAnchor, let index = storage.index(id: anchor) {
					viewportWindow = windowing.centeredWindow(on: index, totalCount: storage.count)
				} else {
					viewportWindow = windowing.defaultWindow(totalCount: storage.count)
				}
			case let .prepend(anchorID):
				let resolvedAnchor = anchorID ?? scrollAnchor
				scrollAnchor = resolvedAnchor
				if let resolvedAnchor, let index = storage.index(id: resolvedAnchor) {
					viewportWindow = windowing.centeredWindow(on: index, totalCount: storage.count)
				} else {
					viewportWindow = windowing.defaultWindow(totalCount: storage.count)
				}
			}
			ensureLayouts(in: normalizedWindow())
		}
	}

	private func upsert(_ msg: Message) -> UpsertResult {
		if let existingIndex = storage.index(id: msg.uid) {
			let model = storage[existingIndex]
			let previousMessage = model.msg
			model.update(with: msg)
			let sameOrderKey = previousMessage.date == msg.date && previousMessage.uid == msg.uid
			if sameOrderKey {
				invalidateLayoutsForUpdate(at: existingIndex)
				return .init(index: existingIndex, inserted: false)
			}
			storage.remove(id: msg.uid)
			let newIndex = insertionIndex(for: msg)
			storage.insert(model, at: newIndex)
			invalidateLayoutsForMove(from: existingIndex, to: newIndex)
			return .init(index: newIndex, inserted: false)
		}

		let model = model(for: msg)
		model.update(with: msg)
		let index = insertionIndex(for: msg)
		storage.insert(model, at: index)
		invalidateLayoutsAround(index: index)
		return .init(index: index, inserted: true)
	}

	private func insertionIndex(for msg: Message) -> Int {
		var low = 0
		var high = storage.count
		while low < high {
			let mid = (low + high) / 2
			if precedes(storage[mid].msg, msg) {
				low = mid + 1
			} else {
				high = mid
			}
		}
		return low
	}

	private func precedes(_ lhs: Message, _ rhs: Message) -> Bool {
		if lhs.date != rhs.date {
			return lhs.date < rhs.date
		}
		return lhs.uid < rhs.uid
	}

	private func invalidateLayoutsForUpdate(at index: Int) {
		invalidateLayoutsAround(index: index)
		let range = normalizedWindow()
		if range.contains(index) {
			let lower = max(range.lowerBound, max(index - 1, 0))
			let upper = min(range.upperBound, min(index + 2, storage.count))
			if lower < upper {
				ensureLayouts(in: lower ..< upper)
			}
		}
	}

	private func invalidateLayoutsForMove(from oldIndex: Int, to newIndex: Int) {
		invalidateLayoutsAround(index: oldIndex)
		invalidateLayoutsAround(index: newIndex)
		let range = normalizedWindow()
		let lower = max(min(oldIndex, newIndex) - 1, range.lowerBound)
		let upper = min(max(oldIndex, newIndex) + 2, range.upperBound)
		if lower < upper {
			ensureLayouts(in: lower ..< upper)
		}
	}

	private func invalidateLayoutsAround(index: Int) {
		guard !storage.isEmpty else { return }
		let lower = max(0, index - 1)
		let upper = min(storage.count - 1, index + 1)
		if lower > upper { return }
		for i in lower ... upper {
			layoutCache[storage[i].id] = nil
		}
	}

	private func layout(for id: MsgID) -> MsgCellLayout? {
		guard let index = storage.index(id: id) else { return nil }
		if let cached = layoutCache[id] {
			storage[index].update(layout: cached)
			return cached
		}

		let prevMsg = index > 0 ? storage[index - 1].msg : nil
		let nextMsg = index + 1 < storage.count ? storage[index + 1].msg : nil
		let style = bubbleFactory.style(for: storage[index].msg, previous: prevMsg, next: nextMsg)
		layoutCache[id] = style
		storage[index].update(layout: style)
		return style
	}

	private func ensureLayouts(in range: Range<Int>) {
		guard !range.isEmpty else { return }
		for index in range {
			_ = layout(for: storage[index].id)
		}
	}

	private func adjustViewport(around index: Int) {
		let nextWindow = windowing.adjustAroundVisible(
			index: index,
			current: viewportWindow,
			totalCount: storage.count
		)
		guard nextWindow != viewportWindow else { return }
		viewportWindow = nextWindow
		ensureLayouts(in: viewportWindow)
		evictLayoutsIfNeeded()
	}

	private func adjustViewportForMutation(at index: Int, inserted: Bool) {
		viewportWindow = windowing.adjustForMutation(
			index: index,
			inserted: inserted,
			current: viewportWindow,
			totalCount: storage.count
		)
		ensureViewportBounds()
		evictLayoutsIfNeeded()
	}

	private func adjustViewportForRemoval(removedID id: MsgID) {
		if scrollAnchor == id {
			scrollAnchor = nil
		}
		ensureViewportBounds()
	}

	private func normalizedWindow() -> Range<Int> {
		windowing.normalized(viewportWindow, totalCount: storage.count)
	}

	private func ensureViewportBounds() {
		viewportWindow = windowing.ensureBounds(viewportWindow, totalCount: storage.count)
		evictLayoutsIfNeeded()
	}

	private func evictLayoutsIfNeeded() {
		guard layoutCache.count > maxLayoutCacheCount else { return }
		let window = normalizedWindow()
		guard !window.isEmpty else {
			layoutCache.removeAll(keepingCapacity: true)
			return
		}
		let padding = max(16, windowing.windowSize / 2)
		let keepLower = max(0, window.lowerBound - padding)
		let keepUpper = min(storage.count, window.upperBound + padding)
		let keepRange = keepLower ..< keepUpper
		var keepIDs = Set<MsgID>()
		keepIDs.reserveCapacity(keepRange.count)
		for index in keepRange {
			keepIDs.insert(storage[index].id)
		}
		layoutCache = layoutCache.filter { keepIDs.contains($0.key) }
	}

	static func resolveWindowSize() -> Int {
		#if DEBUG
			if let configured = ProcessInfo.processInfo.environment["CHAT_PERF_WINDOW_SIZE"]
				.flatMap(Int.init) {
				return max(20, configured)
			}
		#endif
		return 220
	}

	private func withBatchUpdate(_ work: () -> Void) {
		var transaction = Transaction()
		transaction.disablesAnimations = true
		withTransaction(transaction) {
			work()
		}
	}
}
