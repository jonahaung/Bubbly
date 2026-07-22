//  Messages.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import Database
import Foundation
import Services
import SwiftUI
import XUI

@MainActor final class Messages: Sendable {
    
    var wrappedValue: [MsgCellViewModel] = []
    private var indexMap: [String: Int] = [:]
    private let cellDecorator: MsgCellDecorator = .init()
    private var modelCache = LRUCache<MsgCellViewModel.ID, MsgCellViewModel>()
    private let markdownFormatter: MarkdownFormatter = .init()
    private let richTextEnabled: Bool
    private var visibleIDs: [String] = []
    private var visibleIDSet = Set<String>()
    var paginatableState: PaginatableState?
    var pagination: PaginationState
    private let debouncer = Debouncer(delay: 0.2, queue: .global())
    let layout = MsgsScrollViewLayoutManager()
    var selectedMsg: SelectedMsg?
    
    init(_ msgs: [Message], pagination: PaginationState) {
        self.pagination = pagination
        richTextEnabled = UserDefaults.group.bool(
            forKey: GroupStorageKey.conversation(.richTextEnabled).value
        )
        wrappedValue = makeModels(from: msgs)
        rebuildIndexMap()
        updatePaginatableState()
    }
    
    deinit { log("deinit") }
}

extension Messages {
    
    var count: Int { wrappedValue.count }
    var first: MsgCellViewModel? { wrappedValue.first }
    var last: MsgCellViewModel? { wrappedValue.last }
    var shouldShowHeader: Bool { !shouldPaginate(at: .top) }
    var shouldAdjustWindow: Bool { count > pagination.pageSize * 2 }
    func contains(withID id: String) -> Bool { indexMap[id] != nil }
    func index(of id: String) -> Int? { indexMap[id] }

    subscript(position: Int) -> MsgCellViewModel? {
        guard wrappedValue.indices.contains(position) else { return nil }
        return wrappedValue[position]
    }

    func element(withID id: String) -> MsgCellViewModel? {
        guard let index = indexMap[id] else { return nil }
        return wrappedValue[index]
    }

    func isScrolled(at edge: VerticalEdge) -> Bool {
        switch edge {
        case .top:
            guard let first else { return false }
            return visibleIDSet.contains(first.id)
        case .bottom:
            guard let last else { return false }
            return visibleIDSet.contains(last.id)
        }
    }

    func shouldPaginate(at edge: VerticalEdge) -> Bool {
        switch edge {
        case .top:
            return if let firstMsgID = pagination.firstMsgID {
                !contains(withID: firstMsgID)
            } else {
                false
            }
        case .bottom:
            return if let lastMsgID = pagination.lastMsgID {
                !contains(withID: lastMsgID)
            } else {
                false
            }
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

    func firstVisibleDateString() -> String? {
        guard let id = visibleIDs.first, let model = element(withID: id) else {
            return nil
        }
        return MsgTimeStringFormatter.string(for: model.msg.date)
    }
}

extension Messages {
    func onScrollTargetVisibilityChange(_ ids: [String]) {
        displayVisibleMsgsIfNeeded(currentVisibleIDs: ids)
    }

    func refreshMsg(uid: String) async throws {
        guard let updated = try await Store.shared.msgStore?.fetch(uid: uid)
        else {
            return
        }
        element(withID: uid)?.update(with: updated)
    }

    func refreshMsgs(uids: [String]) async throws {
        try await AsyncOrderedStream.mapOrdered(inputs: uids) {
            [weak self] uid in
            guard let self else { return }
            try await refreshMsg(uid: uid)
        }
    }

    func didChangeSelection(_ selectedMsg: SelectedMsg?, for id: String) {
        guard let index = indexMap[id] else { return }
        wrappedValue[index].update(selectedMsg: selectedMsg)
    }
}

extension Messages {
    func set(msgs: [Message]) {
        wrappedValue = makeModels(from: msgs)
        rebuildIndexMap()
        pruneVisibleIDs()
        updatePaginatableState()
    }

    func insert(msg: Message) {
        upsert(msg)
    }

    func remove(msg: Message) {
        guard let index = indexMap[msg.uid] else { return }
        wrappedValue.remove(at: index)
        modelCache.remove(msg.uid)
        updateIndexMap(from: index)
        relayoutNeighbors(aroundRemovalAt: index)
        removeVisibleID(msg.uid)
        updatePagination()
    }

    func prepend(_ msgs: [Message]) {
        guard !msgs.isEmpty else { return }

        var newMessages: [Message] = []
        newMessages.reserveCapacity(msgs.count)

        for msg in msgs {
            if let index = indexMap[msg.uid] {
                layout(at: index)
            } else {
                newMessages.append(msg)
            }
        }

        guard !newMessages.isEmpty else {
            updatePaginatableState()
            return
        }

        let models = makeModels(
            from: newMessages,
            nextBoundary: wrappedValue.first?.msg
        )
        wrappedValue.insert(contentsOf: models, at: 0)
        rebuildIndexMap()
        if wrappedValue.count > models.count {
            layout(at: models.count)
        }
        updatePaginatableState()
    }

    func append(_ msgs: [Message]) {
        guard !msgs.isEmpty else { return }

        var newMessages: [Message] = []
        newMessages.reserveCapacity(msgs.count)

        for msg in msgs {
            if let index = indexMap[msg.uid] {
                layout(at: index)
            } else {
                newMessages.append(msg)
            }
        }

        guard !newMessages.isEmpty else {
            updatePaginatableState()
            return
        }

        let start = wrappedValue.count
        let models = makeModels(
            from: newMessages,
            previousBoundary: wrappedValue.last?.msg
        )
        wrappedValue.append(contentsOf: models)
        rebuildIndexMap()
        if start > 0 {
            layout(at: start - 1)
        }
        updatePaginatableState()
    }

    func retainOldest(_ limit: Int) {
        guard limit >= 0, wrappedValue.count > limit else { return }
        wrappedValue.removeSubrange(limit..<wrappedValue.count)
        rebuildIndexMap()
        pruneVisibleIDs()
        if let lastIndex = wrappedValue.indices.last {
            layout(at: lastIndex)
        }
        updatePaginatableState()
    }

    func retainNewest(_ limit: Int) {
        guard limit >= 0, wrappedValue.count > limit else { return }
        let removeCount = wrappedValue.count - limit
        wrappedValue.removeSubrange(0..<removeCount)
        rebuildIndexMap()
        pruneVisibleIDs()
        if !wrappedValue.isEmpty {
            layout(at: 0)
        }
        updatePaginatableState()
    }
}

extension Messages {
    fileprivate func updatePaginatableState() {
        paginatableState = .init(
            canLoadOlder: shouldPaginate(at: .top),
            canLoadNewer: shouldPaginate(at: .bottom),
            canAdjustSize: shouldAdjustWindow
        )
    }

    fileprivate func displayVisibleMsgsIfNeeded(currentVisibleIDs: [String]) {
        let currentSet = Set(currentVisibleIDs)

        for id in currentSet where !visibleIDSet.contains(id) {
            element(withID: id)?.setVisibility(true)
        }

        for id in visibleIDSet where !currentSet.contains(id) {
            element(withID: id)?.setVisibility(false)
        }

        visibleIDs = currentVisibleIDs
        visibleIDSet = currentSet
    }

    fileprivate func model(
        for msg: Message,
        previous: Message? = nil,
        next: Message? = nil
    ) -> MsgCellViewModel {
       
        if let cached = modelCache.get(msg.uid) {
            return cached
        }
        let layout = makeLayout(for: msg, previous: previous, next: next)
        let attributedText = makeAttributedText(for: msg)
        let model = MsgCellViewModel(
            .init(msg: msg, attributedText: attributedText, layout: layout)
        )
        modelCache.set(model, for: msg.uid)
        return model
    }

    fileprivate func makeModels(
        from msgs: [Message],
        previousBoundary: Message? = nil,
        nextBoundary: Message? = nil
    ) -> [MsgCellViewModel] {
        var models: [MsgCellViewModel] = []
        models.reserveCapacity(msgs.count)

        for index in msgs.indices {
            let previous = index > 0 ? msgs[index - 1] : previousBoundary
            let next = index + 1 < msgs.count ? msgs[index + 1] : nextBoundary
            models.append(
                model(for: msgs[index], previous: previous, next: next)
            )
        }

        return models
    }

    fileprivate func upsert(_ msg: Message) {
        if let index = indexMap[msg.uid] {
            layout(at: index)
            return
        }

        let index = insertionIndex(for: msg)
        let previous = index > 0 ? wrappedValue[index - 1].msg : nil
        let next = index < wrappedValue.count ? wrappedValue[index].msg : nil
        let model = model(for: msg, previous: previous, next: next)
        wrappedValue.insert(model, at: index)
        updateIndexMap(from: index)
        relayoutNeighbors(aroundInsertionAt: index)
        if index == wrappedValue.count - 1 {
            pagination.lastMsgID = msg.uid
        }
        updatePagination()
    }
    
    fileprivate func relayoutNeighbors(aroundInsertionAt index: Int) {
        if index > 0 {
            layout(at: index - 1)
        }
        if index + 1 < wrappedValue.count {
            layout(at: index + 1)
        }
    }

    fileprivate func relayoutNeighbors(aroundRemovalAt index: Int) {
        if index > 0 {
            layout(at: index - 1)
        }
        if index < wrappedValue.count {
            layout(at: index)
        }
    }

    fileprivate func relayoutNeighbors(aroundUpdateAt index: Int) {
        if index > 0 {
            layout(at: index - 1)
        }
        layout(at: index)
        if index + 1 < wrappedValue.count {
            layout(at: index + 1)
        }
    }

    fileprivate func layout(at index: Int) {
        let model = wrappedValue[index]
        let previous = index > 0 ? wrappedValue[index - 1].msg : nil
        let next =
            index + 1 < wrappedValue.count ? wrappedValue[index + 1].msg : nil
        model.update(
            layout: makeLayout(for: model.msg, previous: previous, next: next)
        )
    }

    fileprivate func makeAttributedText(for msg: Message) -> AttributedString? {
        guard let text = msg.text else { return nil }
        return richTextEnabled
            ? markdownFormatter.richText(for: text)
            : markdownFormatter.markdownText(for: text)
    }

    fileprivate func makeLayout(
        for msg: Message,
        previous: Message?,
        next: Message?
    ) -> MsgCellDecoration {
        cellDecorator.style(for: msg, previous: previous, next: next)
    }
    fileprivate func rebuildIndexMap() {
        indexMap.removeAll(keepingCapacity: true)
        for (index, model) in wrappedValue.enumerated() {
            indexMap[model.id] = index
        }
    }

    fileprivate func updateIndexMap(from start: Int) {
        guard start >= 0 else { return }
        for index in start..<wrappedValue.count {
            indexMap[wrappedValue[index].id] = index
        }
    }

    fileprivate func pruneVisibleIDs() {
        guard !visibleIDs.isEmpty else { return }
        visibleIDs.removeAll { indexMap[$0] == nil }
        visibleIDSet = Set(visibleIDs)
    }

    fileprivate func removeVisibleID(_ id: String) {
        guard visibleIDSet.remove(id) != nil else { return }
        visibleIDs.removeAll { $0 == id }
    }

    fileprivate func insertionIndex(for msg: Message) -> Int {
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

    fileprivate func needsReorder(for msg: Message, at index: Int) -> Bool {
        if index > 0, precedes(msg, wrappedValue[index - 1].msg) {
            return true
        }
        if index + 1 < wrappedValue.count,
            precedes(wrappedValue[index + 1].msg, msg)
        {
            return true
        }
        return false
    }

    fileprivate func precedes(_ lhs: Message, _ rhs: Message) -> Bool {
        if lhs.date != rhs.date {
            return lhs.date < rhs.date
        }
        return lhs.uid < rhs.uid
    }
    private func updatePagination() {
        Task {
            do {
               guard let firstMsgID = try await MsgRepo.firstMsg(conID: pagination.conID),
                        let lasMsgID = try await MsgRepo.lastMsg(conID: pagination.conID) else { return }
                let totalMsgCount = try await MsgRepo.totalMsgsCount(conID: pagination.conID)
                print(totalMsgCount)
                pagination = .init(conID: pagination.conID, pageSize: pagination.pageSize, lastMsgID: lasMsgID.uid, firstMsgID: firstMsgID.uid, totalMsgsCount: totalMsgCount)
                print(pagination)
                updatePaginatableState()
            } catch {
                log(error)
            }
        }
    }
}
