// © 2026 Aung Ko Min

import Core
import Database
import Foundation
import Services
import SwiftUI
import XUI

// MARK: - MsgModels

@MainActor
final class Messages {

    // MARK: - Init

    init(_ msgs: [Message] = [], _ headerModels: [HeaderModel] = []) {
        self.headerModels = headerModels
        richTextEnabled = UserDefaults.group.bool(
            forKey: GroupStorageKey.conversation(.richTextEnabled).value
        )

        storage = msgs.map(model(for:))
        rebuildIndexMap()
        layoutBatch(storage)
    }

    deinit { log("deinit") }

    // MARK: - Public

    var headerModels = [HeaderModel]()

    var count: Int { storage.count }
    var first: MsgCellViewModel? { storage.first }
    var last: MsgCellViewModel? { storage.last }
    var isEmpty: Bool { storage.isEmpty }
    var renderedModels: [MsgCellViewModel] { storage }

    func contains(withID id: String) -> Bool {
        indexMap[id] != nil
    }

    func index(of id: String) -> Int? {
        indexMap[id]
    }

    subscript(position: Int) -> MsgCellViewModel? {
        storage[safe: position]
    }

    func element(withID id: String) -> MsgCellViewModel? {
        guard let index = indexMap[id] else { return nil }
        return storage[index]
    }

    // MARK: - Storage

    private var storage = [MsgCellViewModel]()
    private var indexMap: [String: Int] = [:]

    private let bubbleFactory = BubbleFactory()
    private var modelCache = LRUCache<MsgCellViewModel.ID, MsgCellViewModel>()
    private let markdownFormatter = MarkdownFormatter()
    private let richTextEnabled: Bool
    private var currentVisibleIDS = [String]()
}

extension Messages {

    func didBecomeVisible(ids: [String]) -> String? {
//        currentVisibleIDS = ids
        var dateString: String?

        for id in ids {
            guard let index = indexMap[id] else { continue }
            let model = storage[index]

            if !model.isVisible {
                model.setVisibility(true)

                if dateString == nil,
                    model.state.layout.showTimeSeparator
                {
                    dateString = model.state.dateStString
                }
            }
        }

        return dateString
    }
}
extension Messages {
    func displayVisibleMsgsIfNeeded() {
        let diff = storage.filter{ $0.isVisible }.map(\.id).difference(from: currentVisibleIDS)
        diff.forEach { each in
            switch each {
            case .insert:
                break
            case let .remove(_, id, _):
                element(withID: id)?.setVisibility(false)
            }
        }
    }
}
extension Messages {

    var msgs: [Message] {
        storage.map(\.msg)
    }
    func didChangeSelection(_ selectedMsg: SelectedMsg?, for id: String) {
        guard let index = indexMap[id] else { return }
        storage[index].update(selectedMsg: selectedMsg)
    }

    func set(msgs: [Message]) {
        storage = msgs.map(model(for:))
        rebuildIndexMap()
        layoutBatch(storage)
    }

    func insert(msg: Message) {
        let index = insertionIndex(for: msg)
        let model = model(for: msg)

        storage.insert(model, at: index)
        rebuildIndexMap()

        layoutAround(index)
    }

    func update(msg: Message) {
        modelCache.get(msg.uid)?.update(with: msg)
    }

    func remove(msg: Message) {
        guard let index = indexMap[msg.uid] else { return }

        storage.remove(at: index)
        modelCache.remove(msg.uid)

        rebuildIndexMap()
        layoutAround(index)
    }

    func prepend(_ msgs: [Message]) async {
        let models = msgs.map(model(for:))
        layoutBatch(models)

        storage.insert(contentsOf: models, at: 0)
        rebuildIndexMap()
    }

    func append(_ msgs: [Message]) async {
        let models = msgs.map(model(for:))
        layoutBatch(models)

        let start = storage.count
        storage.append(contentsOf: models)

        rebuildIndexMap()
        layoutAround(start)
    }

    func retainOldest(_ limit: Int) async {
        guard limit >= 0, storage.count > limit else { return }

        storage.removeSubrange(limit..<storage.count)
        rebuildIndexMap()

        if let lastIndex = storage.indices.last {
            layoutAround(lastIndex)
        }
    }

    func retainNewest(_ limit: Int) async {
        guard limit >= 0, storage.count > limit else { return }

        let removeCount = storage.count - limit
        storage.removeSubrange(0..<removeCount)

        rebuildIndexMap()

        if !storage.isEmpty {
            layoutAround(0)
        }
    }
}

extension Messages {
    func applyDiff(old: [Message], new: [Message]) {

        let changes = Diff.diff(old: old, new: new)

        for change in changes {
            switch change.kind {

            case .remove(let index):
                storage.remove(at: index)

            case .insert(let index):
                let model = model(for: change.message)
                storage.insert(model, at: index)

            case .update(let index):
                storage[index].update(with: change.message)
            }
        }

        rebuildIndexMap()
        layoutBatch(storage)
    }
    func model(for msg: Message) -> MsgCellViewModel {

        if let cached = modelCache.get(msg.uid) {
            return cached
        }

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
        modelCache.set(msg.uid, value: model)

        return model
    }
}

extension Messages {

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

        for i in lower...upper {
            layout(at: i)
        }
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
        for (i, model) in storage.enumerated() {
            indexMap[model.id] = i
        }
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
}

extension MsgCellViewModel {
    var identified: Identified<String, MsgCellViewModel> {
        .init(self, id: \.id)
    }
}
