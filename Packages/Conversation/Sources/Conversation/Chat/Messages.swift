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

@MainActor
final class Messages {

    private let cellDecorator: MsgCellDecorator = .init()
    private let markdownFormatter: MarkdownFormatter = .init()
    private let richTextEnabled: Bool

    private var indexMap: [String: Int] = [:]
    private var modelCache = LRUCache<MsgCellViewModel.ID, MsgCellViewModel>()
    private var visibleIDs: [String] = []
    private let debouncer = Debouncer(delay: 0.2, queue: .global())

    var wrappedValue: [MsgCellViewModel] = []
    var selectedMsg: SelectedMsg?
    var pagination: PaginationState
    let layout = MsgsScrollViewLayoutManager()

    init(_ messages: [Message], pagination: PaginationState) {
        self.pagination = pagination
        richTextEnabled = UserDefaults.group.bool(forKey: GroupStorageKey.conversation(.richTextEnabled).value)
        wrappedValue = makeModels(from: messages)
        rebuildIndexMap()
    }

    deinit {
        log("deinit")
    }
}

// MARK: - Queries

extension Messages {

    var count: Int { wrappedValue.count }
    var first: MsgCellViewModel? { wrappedValue.first }
    var last: MsgCellViewModel? { wrappedValue.last }
    var shouldShowHeader: Bool { !shouldPaginate(at: .top) }
    var shouldAdjustWindow: Bool { count > pagination.pageSize * 3 }

    subscript(position: Int) -> MsgCellViewModel? {
        guard wrappedValue.indices.contains(position) else { return nil }
        return wrappedValue[position]
    }

    func contains(withID id: String) -> Bool {
        indexMap[id] != nil
    }

    func index(of id: String) -> Int? {
        indexMap[id]
    }

    func element(withID id: String) -> MsgCellViewModel? {
        guard let index = indexMap[id] else { return nil }
        return wrappedValue[index]
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
        let boundaryID = boundaryMessageID(for: edge)
        guard let boundaryID else { return false }
        return !contains(withID: boundaryID)
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
        guard let id = visibleIDs.first, let model = element(withID: id) else { return nil }
        return MsgTimeStringFormatter.string(for: model.msg.date)
    }

    private func boundaryMessageID(for edge: VerticalEdge) -> String? {
        switch edge {
        case .top: pagination.firstMsgID
        case .bottom: pagination.lastMsgID
        }
    }
}

// MARK: - Visibility & Refresh

extension Messages {

    func onScrollTargetVisibilityChange(_ ids: [String]) {
        displayVisibleMsgsIfNeeded(newValue: ids)
    }

    func refreshMsg(uid: String) async throws {
        guard let updated = try await Store.shared.msgStore?.fetch(uid: uid) else { return }
        element(withID: uid)?.update(with: updated)
    }

    func refreshMsgs(uids: [String]) async throws {
        try await AsyncOrderedStream.mapOrdered(inputs: uids) { [weak self] uid in
            guard let self else { return }
            try await refreshMsg(uid: uid)
        }
    }

    func didChangeSelection(_ selectedMsg: SelectedMsg?, for id: String) {
        guard let index = indexMap[id] else { return }
        wrappedValue[index].update(selectedMsg: selectedMsg)
    }
}

// MARK: - Mutation

extension Messages {

    func set(msgs messages: [Message]) {
        wrappedValue = makeModels(from: messages)
        rebuildIndexMap()
        pruneVisibleIDs()
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
        Task {
            try? await updatePagination()
        }
    }

    func prepend(_ messages: [Message]) {
        guard !messages.isEmpty else { return }
        let models = makeModels(from: messages, nextBoundary: wrappedValue.first?.msg)
        wrappedValue.insert(contentsOf: models, at: 0)
        rebuildIndexMap()
        if wrappedValue.count > models.count {
            layout(at: models.count)
        }
    }

    func append(_ messages: [Message]) {
        guard !messages.isEmpty else { return }
        let start = wrappedValue.count
        let models = makeModels(from: messages, previousBoundary: wrappedValue.last?.msg)
        wrappedValue.append(contentsOf: models)
        rebuildIndexMap()
        if start > 0 {
            layout(at: start - 1)
        }
    }

    func retainOldest(_ limit: Int) {
        guard limit >= 0, wrappedValue.count > limit else { return }
        wrappedValue.removeSubrange(limit..<wrappedValue.count)
        rebuildIndexMap()
        pruneVisibleIDs()
        if let lastIndex = wrappedValue.indices.last {
            layout(at: lastIndex)
        }
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
    }
}

// MARK: - Pagination

extension Messages {

    func updatePagination() async throws {
        guard let firstMessage = try await MsgRepo.firstMsg(conID: pagination.conID),
            let lastMessage = try await MsgRepo.lastMsg(conID: pagination.conID)
        else {
            return
        }

        let totalCount = try await MsgRepo.totalMsgsCount(conID: pagination.conID)

        pagination = PaginationState(
            conID: pagination.conID,
            pageSize: pagination.pageSize,
            lastMsgID: lastMessage.uid,
            firstMsgID: firstMessage.uid,
            totalMsgsCount: totalCount
        )
    }

    func paginatableState() -> PaginatableState {
        PaginatableState(
            canLoadOlder: shouldPaginate(at: .top),
            canLoadNewer: shouldPaginate(at: .bottom),
            canAdjustSize: shouldAdjustWindow
        )
    }
}

// MARK: - Private Helpers

private extension Messages {

    func displayVisibleMsgsIfNeeded(newValue: [String]) {
        let differences = newValue.difference(from: visibleIDs)
        visibleIDs = newValue

        for change in differences {
            switch change {
            case .insert(_, let id, _):
                element(withID: id)?.setVisibility(true)
            case .remove(_, let id, _):
                element(withID: id)?.setVisibility(false)
            }
        }
    }

    func model(for msg: Message, previous: Message? = nil, next: Message? = nil) -> MsgCellViewModel {
        let layout = makeLayout(for: msg, previous: previous, next: next)

        if let cached = modelCache.get(msg.uid) {
            cached.update(layout: layout)
            return cached
        }

        let attributedText = makeAttributedText(for: msg)
        let model = MsgCellViewModel(.init(msg: msg, attributedText: attributedText, layout: layout))
        modelCache.set(model, for: msg.uid)
        return model
    }

    func makeModels(
        from messages: [Message],
        previousBoundary: Message? = nil,
        nextBoundary: Message? = nil
    ) -> [MsgCellViewModel] {
        var models: [MsgCellViewModel] = []
        models.reserveCapacity(messages.count)

        for index in messages.indices {
            let previous = index > 0 ? messages[index - 1] : previousBoundary
            let next = index + 1 < messages.count ? messages[index + 1] : nextBoundary
            models.append(model(for: messages[index], previous: previous, next: next))
        }

        return models
    }

    func upsert(_ msg: Message) {
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

        Task {
            try? await updatePagination()
        }
    }
}

// MARK: - Layout Helpers

private extension Messages {

    func relayoutNeighbors(aroundInsertionAt index: Int) {
        if index > 0 {
            layout(at: index - 1)
        }
        if index + 1 < wrappedValue.count {
            layout(at: index + 1)
        }
    }

    func relayoutNeighbors(aroundRemovalAt index: Int) {
        if index > 0 {
            layout(at: index - 1)
        }
        if index < wrappedValue.count {
            layout(at: index)
        }
    }

    func relayoutNeighbors(aroundUpdateAt index: Int) {
        if index > 0 {
            layout(at: index - 1)
        }
        layout(at: index)
        if index + 1 < wrappedValue.count {
            layout(at: index + 1)
        }
    }

    func layout(at index: Int) {
        let model = wrappedValue[index]
        let previous = index > 0 ? wrappedValue[index - 1].msg : nil
        let next = index + 1 < wrappedValue.count ? wrappedValue[index + 1].msg : nil
        model.update(layout: makeLayout(for: model.msg, previous: previous, next: next))
    }

    func makeAttributedText(for msg: Message) -> AttributedString? {
        guard let text = msg.text else { return nil }
        return richTextEnabled
            ? markdownFormatter.richText(for: text)
            : markdownFormatter.markdownText(for: text)
    }

    func makeLayout(for msg: Message, previous: Message?, next: Message?) -> MsgCellDecoration {
        cellDecorator.style(for: msg, previous: previous, next: next)
    }
}

// MARK: - Index Management

private extension Messages {

    func rebuildIndexMap() {
        indexMap.removeAll(keepingCapacity: true)
        for (index, model) in wrappedValue.enumerated() {
            indexMap[model.id] = index
        }
    }

    func updateIndexMap(from start: Int) {
        guard start >= 0 else { return }
        for index in start..<wrappedValue.count {
            indexMap[wrappedValue[index].id] = index
        }
    }

    func pruneVisibleIDs() {
        guard !visibleIDs.isEmpty else { return }
        visibleIDs.removeAll { indexMap[$0] == nil }
    }

    func removeVisibleID(_ id: String) {
        visibleIDs.removeAll { $0 == id }
    }
}

// MARK: - Ordering

private extension Messages {

    func insertionIndex(for msg: Message) -> Int {
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

    func needsReorder(for msg: Message, at index: Int) -> Bool {
        if index > 0, precedes(msg, wrappedValue[index - 1].msg) {
            return true
        }
        if index + 1 < wrappedValue.count, precedes(wrappedValue[index + 1].msg, msg) {
            return true
        }
        return false
    }

    func precedes(_ lhs: Message, _ rhs: Message) -> Bool {
        if lhs.date != rhs.date {
            return lhs.date < rhs.date
        }
        return lhs.uid < rhs.uid
    }
}
