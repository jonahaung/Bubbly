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
    public typealias MsgID = Message.UID

    public struct ScrollCompensation: Sendable, Equatable {
        public let anchorID: MsgID?
        public let insertedBeforeAnchor: Int
    }

    private struct UpsertResult {
        let index: Int
        let inserted: Bool
    }

    private var storage = IdentifiedArray<MsgID, MsgCellViewModel>(id: \MsgCellViewModel.id)
    private let modelCache = LRUCache<MsgID, MsgCellViewModel>(capacity: 200)
    private let layoutCache = LRUCache<MsgID, MsgCellLayout>(capacity: 200)
    private let bubbleFactory = BubbleFactory()

    private let mergeActor = MsgMergeActor()

    init(_ msgs: [Message] = []) {
        set(msgs: msgs, forceReset: true)
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
        Array(storage)
    }

    public func contains(withID id: MsgID) -> Bool {
        storage[id: id] != nil
    }

    public func index(of id: MsgID) -> Int? {
        storage.index(id: id)
    }

    public subscript(position: Int) -> MsgCellViewModel? {
        storage.indices.contains(position) ? storage[position] : nil
    }

    public subscript(safe position: Int) -> MsgCellViewModel? {
        storage.indices.contains(position) ? storage[position] : nil
    }

    public func element(withID id: MsgID) -> MsgCellViewModel? {
        storage[id: id] ?? modelCache.get(id)
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
    public func cached(for id: MsgID) -> MsgCellViewModel? {
        modelCache.get(id)
    }

    public func model(for msg: Message) -> MsgCellViewModel {
        if let cached = modelCache.get(msg.uid) { return cached }
        let model = MsgCellViewModel(msg)
        modelCache.set(msg.uid, value: model)
        return model
    }

    public func ensureLayout(for id: MsgID) {
        _ = layout(for: id)
    }

    public func didChangeVisibility(for id: MsgID, isVisible: Bool) {
        element(withID: id)?.setVisibility(isVisible)
    }

    @discardableResult
    public func jump(to id: MsgID) -> Bool {
        guard storage.index(id: id) != nil else { return false }
        ensureLayout(for: id)
        return true
    }

    public func set(msgs: [Message], forceReset: Bool) {
        merge(msgs: msgs, forceReset: forceReset)
    }

    public func setInBackground(msgs: [Message], forceReset: Bool) async {
        let prepared = await mergeActor.prepare(msgs)

        mergePrepared(prepared, forceReset: forceReset)
    }

    @discardableResult
    public func prepend(msgs: [Message], preserveAnchor anchorID: MsgID?) -> ScrollCompensation {
        let beforeIndex = anchorID.flatMap { storage.index(id: $0) }
        merge(msgs: msgs, forceReset: false)
        let afterIndex = anchorID.flatMap { storage.index(id: $0) }
        let insertedBeforeAnchor = max(0, (afterIndex ?? 0) - (beforeIndex ?? afterIndex ?? 0))
        return .init(anchorID: anchorID, insertedBeforeAnchor: insertedBeforeAnchor)
    }

    public func insert(msg: Message) {
        withBatchUpdate {
            _ = upsert(msg)
            evictLayoutsIfNeeded()
        }
    }

    public func update(msg: Message) {
        withBatchUpdate {
            _ = upsert(msg)
        }
    }

    public func remove(msg: Message) {
        withBatchUpdate {
            guard let removedIndex = storage.index(id: msg.uid) else { return }
            storage.remove(id: msg.uid)
            layoutCache.remove(msg.uid)
            invalidateLayoutsAround(index: removedIndex)
            evictLayoutsIfNeeded()
        }
    }

    public func retainOldest(_ limit: Int) {
        guard limit >= 0 else { return }
        withBatchUpdate {
            guard storage.count > limit else { return }
            var removedIDs: [MsgID] = []
            removedIDs.reserveCapacity(storage.count - limit)
            for index in limit..<storage.count {
                removedIDs.append(storage[index].id)
            }
            storage.removeSubrange(limit..<storage.count)
            for id in removedIDs {
                layoutCache.remove(id)
            }
            evictLayoutsIfNeeded()
        }
    }

    public func retainNewest(_ limit: Int) {
        guard limit >= 0 else { return }
        withBatchUpdate {
            guard storage.count > limit else { return }
            let removeCount = storage.count - limit
            var removedIDs: [MsgID] = []
            removedIDs.reserveCapacity(removeCount)
            for index in 0..<removeCount {
                removedIDs.append(storage[index].id)
            }
            storage.removeSubrange(0..<removeCount)
            for id in removedIDs {
                layoutCache.remove(id)
            }
            evictLayoutsIfNeeded()
        }
    }
}

extension MsgModels {
    private func merge(msgs: [Message], forceReset: Bool) {
        let sortedMsgs = MsgMergeActor.prepareStatic(msgs)
        mergePrepared(sortedMsgs, forceReset: forceReset)
    }

    private func mergePrepared(_ sortedMsgs: [Message], forceReset: Bool) {
        guard !sortedMsgs.isEmpty || forceReset else { return }
        withBatchUpdate {
            if forceReset {
                storage.removeAll(keepingCapacity: true)
                layoutCache.removeAll()
            }

            for msg in sortedMsgs {
                _ = upsert(msg)
            }

            if storage.isEmpty {
                return
            }
            ensureLayouts(in: 0..<storage.count)
            evictLayoutsIfNeeded()
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

    @discardableResult
    private func layout(for id: MsgID) -> MsgCellLayout? {
        guard let index = storage.index(id: id) else { return nil }
        if let cached = layoutCache.get(id) {
            if storage[index].layout.isEmpty {
                storage[index].update(layout: cached)
            }
            return cached
        }

        let prevMsg = index > 0 ? storage[index - 1].msg : nil
        let nextMsg = index + 1 < storage.count ? storage[index + 1].msg : nil
        let style = bubbleFactory.style(for: storage[index].msg, previous: prevMsg, next: nextMsg)
        layoutCache.set(id, value: style)
        storage[index].update(layout: style)
        return style
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

    private func withBatchUpdate(_ work: () -> Void) {
        var transaction = Transaction()
        transaction.scrollPositionUpdatePreservesVelocity = false
        transaction.tracksVelocity = false
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            work()
        }
    }
}

actor MsgMergeActor {

    private let bubbleFactory = BubbleFactory()

    func prepare(_ msgs: [Message]) -> [Message] {
        Self.prepareStatic(msgs)
    }

    func layout(_ msgs: [Message]) -> [MsgCellLayout] {
        var layouts = [MsgCellLayout]()
        for msg in msgs {
            let previous = msgs.previous(msg)
            let next = msgs.next(after: msg)
            let layout = bubbleFactory.style(for: msg, previous: previous, next: next)
            layouts.append(layout)
        }
        return layouts
    }

    nonisolated static func prepareStatic(_ msgs: [Message]) -> [Message] {
        guard msgs.count > 1 else { return msgs }
        var alreadySorted = true
        for index in 1..<msgs.count where precedes(msgs[index], msgs[index - 1]) {
            alreadySorted = false
            break
        }
        if alreadySorted {
            return msgs
        }
        return msgs.sorted(by: precedes)
    }

    private nonisolated static func precedes(_ lhs: Message, _ rhs: Message) -> Bool {
        if lhs.date != rhs.date {
            return lhs.date < rhs.date
        }
        return lhs.uid < rhs.uid
    }
}
