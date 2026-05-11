//  Messages.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database
import Services
import Foundation

@MainActor final class Messages: Sendable {
    private var storage: [MsgCellViewModel] = []
    private var indexMap: [String: Int] = [:]
    private let bubbleFactory: BubbleFactory = .init()
    private var modelCache = LRUCache<MsgCellViewModel.ID, MsgCellViewModel>()
    private let markdownFormatter: MarkdownFormatter = .init()
    private let richTextEnabled: Bool
    private var visibleIDs: [String] = []
    var pagination: PaginationState

    init(_ msgs: [Message], pagination: PaginationState) {
        self.pagination = pagination
        richTextEnabled = UserDefaults.group.bool(
            forKey: GroupStorageKey.conversation(.richTextEnabled).value
        )
        storage = makeModels(from: uniqueMessages(in: msgs))
        rebuildIndexMap()
    }

    var count: Int { storage.count }
    var first: MsgCellViewModel? { storage.first }
    var last: MsgCellViewModel? { storage.last }
    var isEmpty: Bool { storage.isEmpty }
    func contains(withID id: String) -> Bool { indexMap[id] != nil }
    func index(of id: String) -> Int? { indexMap[id] }
    subscript(position: Int) -> MsgCellViewModel? { storage[safe: position] }
    func element(withID id: String) -> MsgCellViewModel? {
        guard let index = indexMap[id] else { return nil }
        return storage[index]
    }

    deinit { log("deinit") }
}

extension Messages {
    var shouldAdjustSize: Bool {
        count > pagination.pageSize * 2
    }

    func isScrolled(at edge: VerticalEdge) -> Bool {
        switch edge {
        case .top:
            guard let first else { return false }
            return visibleIDs.contains(first.id)
        case .bottom:
            guard let last else { return false }
            return visibleIDs.contains(last.id)
        }
    }

    func canPaginate(at edge: VerticalEdge) -> Bool {
        guard pagination.canPaginate else { return false }
        switch edge {
        case .top:
            return if let firstMsgID = pagination.firstMsgID {
                !contains(withID: firstMsgID)
            } else { false }
        case .bottom:
            return if let lastMsgID = pagination.lastMsgID {
                !contains(withID: lastMsgID)
            } else { false }
        }
    }

    func isAbsoluteScrolled(at edge: VerticalEdge) -> Bool {
        switch edge {
        case .top:
            isScrolled(at: .top) && canPaginate(at: .top) == false
        case .bottom:
            isScrolled(at: .bottom) && canPaginate(at: .bottom) == false
        }
    }
}

extension Messages {
    func onScrollTargetVisibilityChange(_ ids: [String]) {
        displayVisibleMsgsIfNeeded(currentVisibleIDS: ids)
    }

    func getCurrentVisibleDateString() -> String? {
        guard let model = storage.first(where: { $0.isVisible }) else {
            return nil
        }
        return MsgTimeStringFormatter.string(for: model.msg.date)
    }

    private func displayVisibleMsgsIfNeeded(currentVisibleIDS: [String]) {
        for each in currentVisibleIDS.difference(from: visibleIDs) {
            switch each {
            case let .insert(_, id, _):
                if let model = element(withID: id) { model.setVisibility(true) }
            case let .remove(_, id, _):
                if let model = element(withID: id) {
                    model.setVisibility(false)
                }
            }
        }
        visibleIDs = currentVisibleIDS
    }
}

extension Messages {
    func refreshMsg(uid: String) async throws {
        if let updated = try await Store.shared.msgStore?.fetch(uid: uid) {
            element(withID: uid)?.update(with: updated)
        }
    }

    func refreshMsgs(uids: [String]) async throws {
        try await AsyncOrderedStream.mapOrdered(inputs: uids) {
            [weak self] uid in
            guard let self else { return }
            try await refreshMsg(uid: uid)
        }
    }
}

extension Messages {
    func didChangeSelection(_ selectedMsg: SelectedMsg?, for id: String) {
        guard let index = indexMap[id] else { return }
        storage[index].update(selectedMsg: selectedMsg)
    }

    func set(msgs: [Message]) {
        storage = makeModels(from: uniqueMessages(in: msgs))
        rebuildIndexMap()
    }

    func insert(msg: Message) {
        if contains(withID: msg.uid) {
            update(msg: msg)
            return
        }
        let index = insertionIndex(for: msg)
        let previous = index > 0 ? storage[index - 1].msg : nil
        let next = index < storage.count ? storage[index].msg : nil
        let model = model(for: msg, previous: previous, next: next)
        storage.insert(model, at: index)
        rebuildIndexMap()
        relayoutNeighbors(aroundInsertionAt: index)
    }

    func update(msg: Message) { modelCache.get(msg.uid)?.update(with: msg) }

    func remove(msg: Message) {
        guard let index = indexMap[msg.uid] else { return }
        storage.remove(at: index)
        modelCache.remove(msg.uid)
        rebuildIndexMap()
        relayoutNeighbors(aroundRemovalAt: index)
    }

    func prepend(_ msgs: [Message]) {
        let merged = messagesToMerge(msgs)
        guard !merged.isEmpty else { return }
        let models = makeModels(from: merged, nextBoundary: storage.first?.msg)
        storage.insert(contentsOf: models, at: 0)
        rebuildIndexMap()
        if storage.count > models.count { layout(at: models.count) }
    }

    func append(_ msgs: [Message]) {
        let merged = messagesToMerge(msgs)
            .sorted(by: { $0.date < $1.date })
        guard !merged.isEmpty else { return }
        let start = storage.count
        let models = makeModels(
            from: merged,
            previousBoundary: storage.last?.msg
        )
        storage.append(contentsOf: models)
        rebuildIndexMap()
        if start > 0 { layout(at: start - 1) }
    }

    func retainOldest(_ limit: Int) {
        guard limit >= 0, storage.count > limit else { return }
        storage.removeSubrange(limit ..< storage.count)
        rebuildIndexMap()
        if let lastIndex = storage.indices.last { layout(at: lastIndex) }
    }

    func retainNewest(_ limit: Int) {
        guard limit >= 0, storage.count > limit else { return }
        let removeCount = storage.count - limit
        storage.removeSubrange(0 ..< removeCount)
        rebuildIndexMap()
        if !storage.isEmpty { layout(at: 0) }
    }
}

extension Messages {
    func model(for msg: Message, previous: Message? = nil, next: Message? = nil)
        -> MsgCellViewModel
    {
        if let cached = modelCache.get(msg.uid) { return cached }
        let attributedText: AttributedString? = {
            guard let text = msg.text else { return nil }
            return richTextEnabled
                ? markdownFormatter.richText(for: text)
                : markdownFormatter.markDownText(for: text)
        }()
        let style = bubbleFactory.style(
            for: msg,
            previous: previous,
            next: next
        )
        let state = MsgCellViewModel.State(
            msg: msg,
            attributedText: attributedText,
            layout: style
        )
        let model = MsgCellViewModel(state)
        modelCache.set(msg.uid, value: model)
        return model
    }

    private func uniqueMessages(in msgs: [Message]) -> [Message] {
        var seen = Set<String>()
        var result = [Message]()
        result.reserveCapacity(msgs.count)
        for msg in msgs where seen.insert(msg.uid).inserted {
            result.append(msg)
        }
        return result
    }

    private func messagesToMerge(_ msgs: [Message]) -> [Message] {
        var seen = Set<String>()
        var result = [Message]()
        result.reserveCapacity(msgs.count)
        for msg in msgs {
            if seen.insert(msg.uid).inserted == false {
                continue
            }
            if contains(withID: msg.uid) {
                update(msg: msg)
                continue
            }
            result.append(msg)
        }
        return result
    }

    private func makeModels(
        from msgs: [Message],
        previousBoundary: Message? = nil,
        nextBoundary: Message? = nil
    ) -> [MsgCellViewModel] {
        msgs.indices.map { index in
            let previous = index > 0 ? msgs[index - 1] : previousBoundary
            let next = index + 1 < msgs.count ? msgs[index + 1] : nextBoundary
            return model(for: msgs[index], previous: previous, next: next)
        }
    }

    private func relayoutNeighbors(aroundInsertionAt index: Int) {
        if index > 0 { layout(at: index - 1) }
        if index + 1 < storage.count { layout(at: index + 1) }
    }

    private func relayoutNeighbors(aroundRemovalAt index: Int) {
        if index > 0 { layout(at: index - 1) }
        if index < storage.count { layout(at: index) }
    }

    private func layout(at index: Int) {
        let model = storage[index]
        let prev = index > 0 ? storage[index - 1].msg : nil
        let next = index + 1 < storage.count ? storage[index + 1].msg : nil
        let style = bubbleFactory.style(
            for: model.msg,
            previous: prev,
            next: next
        )
        model.update(layout: style)
    }
}

extension Messages {
    private func rebuildIndexMap() {
        indexMap.removeAll(keepingCapacity: true)
        for (i, model) in storage.enumerated() { indexMap[model.id] = i }
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
        if lhs.date != rhs.date { return lhs.date < rhs.date }
        return lhs.uid < rhs.uid
    }
}
