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
    
    var wrappedValue: [MsgCellViewModel] = []
    
    private var indexMap: [String: Int] = [:]
    private let cellDecorator: MsgCellDecorator = .init()
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
        wrappedValue = makeModels(from: uniqueMessages(in: msgs))
        rebuildIndexMap()
    }
    
    deinit { log("deinit") }
}

extension Messages {
    
    var count: Int { wrappedValue.count }
    
    var first: MsgCellViewModel? { wrappedValue.first }
    var last: MsgCellViewModel? { wrappedValue.last }
    
    func contains(withID id: String) -> Bool {
        indexMap[id] != nil
    }
    func index(of id: String) -> Int? {
        indexMap[id]
    }
    subscript(position: Int) -> MsgCellViewModel? {
        guard position >= 0 && position < count else { return nil }
        return wrappedValue[position]
    }
    func element(withID id: String) -> MsgCellViewModel? {
        guard let index = indexMap[id] else { return nil }
        return wrappedValue[index]
    }
    
    var shouldShowHeader: Bool {
        !shouldPaginate(at: .top)
    }
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

    func shouldPaginate(at edge: VerticalEdge) -> Bool {
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
            isScrolled(at: .top) && !shouldPaginate(at: .top)
        case .bottom:
            isScrolled(at: .bottom) && !shouldPaginate(at: .bottom)
        }
    }
}

extension Messages {
    
    func onScrollTargetVisibilityChange(_ ids: [String]) {
        displayVisibleMsgsIfNeeded(currentVisibleIDS: ids)
    }

    func firstVisibleDateString() -> String? {
        guard let id = visibleIDs.first, let model = element(withID: id) else {
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
        wrappedValue[index].update(selectedMsg: selectedMsg)
    }

    func set(msgs: [Message]) {
        wrappedValue = makeModels(from: uniqueMessages(in: msgs))
        rebuildIndexMap()
    }

    func insert(msg: Message) {
        if contains(withID: msg.uid) {
            update(msg: msg)
            return
        }
        let index = insertionIndex(for: msg)
        let previous = index > 0 ? wrappedValue[index - 1].msg : nil
        let next = index < wrappedValue.count ? wrappedValue[index].msg : nil
        let model = model(for: msg, previous: previous, next: next)
        wrappedValue.insert(model, at: index)
        rebuildIndexMap()
        relayoutNeighbors(aroundInsertionAt: index)
        if index == count-1 {
            pagination.lastMsgID = msg.uid
        }
    }

    func update(msg: Message) {
        modelCache.get(msg.uid)?.update(with: msg)
    }

    func remove(msg: Message) {
        guard let index = indexMap[msg.uid] else { return }
        wrappedValue.remove(at: index)
        modelCache.remove(msg.uid)
        rebuildIndexMap()
        relayoutNeighbors(aroundRemovalAt: index)
    }

    func prepend(_ msgs: [Message]) {
        let merged = messagesToMerge(msgs)
        guard !merged.isEmpty else { return }
        let models = makeModels(from: merged, nextBoundary: wrappedValue.first?.msg)
        wrappedValue.insert(contentsOf: models, at: 0)
        rebuildIndexMap()
        if wrappedValue.count > models.count { layout(at: models.count) }
    }

    func append(_ msgs: [Message]) {
        let merged = messagesToMerge(msgs)
            .sorted(by: { $0.date < $1.date })
        guard !merged.isEmpty else { return }
        let start = wrappedValue.count
        let models = makeModels(
            from: merged,
            previousBoundary: wrappedValue.last?.msg
        )
        wrappedValue.append(contentsOf: models)
        rebuildIndexMap()
        if start > 0 { layout(at: start - 1) }
    }

    func retainOldest(_ limit: Int) {
        guard limit >= 0, wrappedValue.count > limit else { return }
        wrappedValue.removeSubrange(limit ..< wrappedValue.count)
        rebuildIndexMap()
        if let lastIndex = wrappedValue.indices.last { layout(at: lastIndex) }
    }

    func retainNewest(_ limit: Int) {
        guard limit >= 0, wrappedValue.count > limit else { return }
        let removeCount = wrappedValue.count - limit
        wrappedValue.removeSubrange(0 ..< removeCount)
        rebuildIndexMap()
        if !wrappedValue.isEmpty { layout(at: 0) }
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
        let style = cellDecorator.style(
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
        modelCache.set(model, for: msg.uid)
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
        if index + 1 < wrappedValue.count { layout(at: index + 1) }
    }

    private func relayoutNeighbors(aroundRemovalAt index: Int) {
        if index > 0 { layout(at: index - 1) }
        if index < wrappedValue.count { layout(at: index) }
    }

    private func layout(at index: Int) {
        let model = wrappedValue[index]
        let prev = index > 0 ? wrappedValue[index - 1].msg : nil
        let next = index + 1 < wrappedValue.count ? wrappedValue[index + 1].msg : nil
        let style = cellDecorator.style(
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
        for (i, model) in wrappedValue.enumerated() { indexMap[model.id] = i }
    }

    private func insertionIndex(for msg: Message) -> Int {
        var low = 0
        var high = wrappedValue.count
        while low < high {
            let mid = (low + high) / 2
            if precedes(wrappedValue[mid].msg, msg) {
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
