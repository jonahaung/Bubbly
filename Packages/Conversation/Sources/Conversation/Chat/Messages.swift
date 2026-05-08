//  Messages.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI

// © 2026 Aung Ko Min
import Core
import SwiftUI
import Database
import Services
import Foundation

@MainActor final class Messages {

    private var storage: [MsgCellViewModel] = []
    private var indexMap: [String: Int] = [:]
    private let bubbleFactory: BubbleFactory = .init()
    private var modelCache = LRUCache<MsgCellViewModel.ID, MsgCellViewModel>(
        capacity: 500
    )
    private let markdownFormatter: MarkdownFormatter = .init()
    private let richTextEnabled: Bool
    private let debouncer: Debouncer = .init(delay: 1)
    var pagination: Pagination
    private var visibleIDs: Set<String> = []

    init(_ pagination: Pagination) {
        self.pagination = pagination
        richTextEnabled = UserDefaults.group.bool(
            forKey: GroupStorageKey.conversation(.richTextEnabled).value
        )
        storage = pagination.msgs.map(model(for:))
        rebuildIndexMap()
        layoutBatch(storage)
    }

    deinit { log("deinit") }
    var count: Int { storage.count }
    var first: MsgCellViewModel? { storage.first }
    var last: MsgCellViewModel? { storage.last }
    var isEmpty: Bool { storage.isEmpty }
    var renderedModels: [MsgCellViewModel] { storage }
}

extension Messages {
    func onScrollTargetVisibilityChange(_ ids: [String]) {
        visibleIDs = .init(ids)
        debouncer.debounce { [weak self] in
            guard let self else { return }
            displayVisibleMsgsIfNeeded(currentVisibleIDS: ids)
        }
    }

    func getCurrentVisibleDateString() -> String? {
        guard let model = storage.first(where: { $0.isVisible }) else {
            return nil
        }
        return MsgTimeStringFormatter.string(for: model.msg.date)
    }

    private func displayVisibleMsgsIfNeeded(currentVisibleIDS: [String]) {
        let oldIDs = storage.filter(\.isVisible).map(\.msg.uid)
        let difference = currentVisibleIDS.difference(from: oldIDs)
        for each in difference {
            switch each {
            case let .insert(_, id, _):
                if let model = element(withID: id) { model.setVisibility(true) }
            case let .remove(_, id, _):
                if let model = element(withID: id) {
                    model.setVisibility(false)
                }
            }
        }
    }

    func isVisible(_ id: String) -> Bool {
        visibleIDs.contains(id)
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
    func contains(withID id: String) -> Bool {
        indexMap[id] != nil
    }

    func index(of id: String) -> Int? {
        indexMap[id]
    }

    subscript(position: Int) -> MsgCellViewModel? { storage[safe: position] }
    func element(withID id: String) -> MsgCellViewModel? {
        guard let index = indexMap[id] else { return nil }
        return storage[index]
    }

    func didChangeSelection(_ selectedMsg: SelectedMsg?, for id: String) {
        guard let index = indexMap[id] else { return }
        storage[index].update(selectedMsg: selectedMsg)
    }

    func set(msgs: [Message]) {
        storage = uniqueMessages(in: msgs).map(model(for:))
        rebuildIndexMap()
        layoutBatch(storage)
    }

    func insert(msg: Message) {
        if contains(withID: msg.uid) {
            update(msg: msg)
            return
        }
        let index = insertionIndex(for: msg)
        let model = model(for: msg)
        storage.insert(model, at: index)
        rebuildIndexMap()
        layoutAround(index)
    }

    func update(msg: Message) { modelCache.get(msg.uid)?.update(with: msg) }
    func remove(msg: Message) {
        guard let index = indexMap[msg.uid] else { return }
        storage.remove(at: index)
        rebuildIndexMap()
        layoutAround(index)
    }

    func prepend(_ msgs: [Message]) {
        let models = messagesToMerge(msgs).map(model(for:))
        let count = models.count
        guard count > 0 else { return }
        layoutBatch(models)
        storage.insert(contentsOf: models, at: 0)
        rebuildIndexMap()
        layoutAround(count - 1)
    }

    func append(_ msgs: [Message]) {
        let models = messagesToMerge(msgs)
            .sorted(by: { $0.date < $1.date })
            .map(model(for:))
        guard !models.isEmpty else { return }
        layoutBatch(models)
        let start = storage.count
        storage.append(contentsOf: models)
        rebuildIndexMap()
        layoutAround(start)
    }

    func retainOldest(_ limit: Int) {
        guard limit >= 0, storage.count > limit else { return }
        storage.removeSubrange(limit ..< storage.count)
        rebuildIndexMap()
        if let lastIndex = storage.indices.last { layoutAround(lastIndex) }
    }

    func retainNewest(_ limit: Int) {
        guard limit >= 0, storage.count > limit else { return }
        let removeCount = storage.count - limit
        storage.removeSubrange(0 ..< removeCount)
        rebuildIndexMap()
        if !storage.isEmpty { layoutAround(0) }
    }
}

extension Messages {
    func model(for msg: Message) -> MsgCellViewModel {
        if let cached = modelCache.get(msg.uid) { return cached }
        let attributedText: AttributedString? = {
            guard let text = msg.text else { return nil }
            return richTextEnabled
                ? markdownFormatter.richText(for: text)
                : markdownFormatter.markDownText(for: text)
        }()
        let state = MsgCellViewModel.State(
            msg: msg,
            attributedText: attributedText
        )
        let model = MsgCellViewModel(state)
        modelCache.set(model, for: msg.uid, ttl: 300)
        return model
    }
}

extension Messages {
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

    private func layoutBatch(_ models: [MsgCellViewModel]) {
        guard !models.isEmpty else { return }
        for i in models.indices {
            let model = models[i]
            let prev = i > 0 ? models[i - 1].msg : nil
            let next = i + 1 < models.count ? models[i + 1].msg : nil
            let style = bubbleFactory.style(
                for: model.msg,
                previous: prev,
                next: next
            )
            model.update(layout: style)
        }
    }

    private func layoutAround(_ index: Int) {
        guard !storage.isEmpty else { return }
        let lower = max(0, index - 1)
        let upper = min(storage.count - 1, index + 1)
        for i in lower ... upper { layout(at: i) }
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

extension Messages {
    func shouldPaginate(at edge: VerticalEdge) -> Bool {
        switch edge {
        case .top:
            guard let id = pagination.firstMsgID else { return false }
            return storage.contains(where: { $0.msg.uid == id }) == false
        case .bottom:
            guard let id = pagination.lastMsgID else { return false }
            return storage.contains(where: { $0.msg.uid == id }) == false
        }
    }

    func isScrolled(at edge: VerticalEdge) -> Bool {
        switch edge {
        case .top:
            guard let id = first?.id else { return false }
            return isVisible(id)
        case .bottom:
            guard let id = last?.id else { return false }
            return isVisible(id)
        }
    }

    func lasMsg() async throws -> Message? {
        guard let uid = pagination.lastMsgID else { return nil }
        return try await Store.shared.msgStore?.fetch(uid: uid)
    }

    func updatePagination() {
        Task {
            pagination.lastMsgID = try await MsgRepo.lastMsg(
                conID: pagination.conID
            )?.uid
            pagination.firstMsgID = try await MsgRepo.firstMsg(
                conID: pagination.conID
            )?.uid
            pagination.totalMsgsCount = try await MsgRepo.totalMsgsCount(
                conID: pagination.conID
            )
        }
    }
}
