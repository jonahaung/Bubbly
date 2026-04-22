// © 2026 Aung Ko Min
import Core
import Database
import Foundation
import Services
import SwiftUI
import XUI
@MainActor final class Messages {
    var headerModels: [HeaderModel] = []
    private var storage: [MsgCellViewModel] = []
    private var indexMap: [String: Int] = [:]
    private let bubbleFactory: BubbleFactory = .init()
    private var modelCache = LRUCache<MsgCellViewModel.ID, MsgCellViewModel>()
    private let markdownFormatter: MarkdownFormatter = .init()
    private let richTextEnabled: Bool
    private let debouncer = Debouncer(delay: 1)
    init(_ msgs: [Message] = [], _ headerModels: [HeaderModel] = []) {
        richTextEnabled = UserDefaults.group.bool(
            forKey: GroupStorageKey.conversation(.richTextEnabled).value, )
        self.headerModels = headerModels
        storage = msgs.map(model(for:))
        rebuildIndexMap()
        layoutBatch(storage)
    }
    deinit { log("deinit") }
    var count: Int { storage.count }
    var first: MsgCellViewModel? { storage.first }
    var last: MsgCellViewModel? { storage.last }
    var isEmpty: Bool { storage.isEmpty }
    var renderedModels: [MsgCellViewModel] { storage }
    func contains(withID id: String) -> Bool { indexMap[id] != nil }
    func index(of id: String) -> Int? { indexMap[id] }
    subscript(position: Int) -> MsgCellViewModel? { storage[safe: position] }
    func element(withID id: String) -> MsgCellViewModel? {
        guard let index = indexMap[id] else { return nil }
        return storage[index]
    }
}
extension Messages {
    func onScrollTargetVisibilityChange(_ ids: [String]) {
        debouncer.debounce { [weak self] in
            guard let self else { return }
            displayVisibleMsgsIfNeeded(currentVisibleIDS: ids)
        }
    }
    func getCurrentVisibleDateString() -> String? {
        guard let model = storage.first(where: { $0.state.isVisible }) else { return nil }
        return MsgTimeStringFormatter.string(for: model.msg.date)
    }
    private func displayVisibleMsgsIfNeeded(currentVisibleIDS: [String]) {
        let oldIDs = storage.filter(\.state.isVisible).map(\.msg.uid)
        let difference = currentVisibleIDS.difference(from: oldIDs)
        for each in difference {
            switch each {
            case .insert(_, let id, _):
                if let model = element(withID: id) { model.setVisibility(true) }
            case .remove(_, let id, _):
                if let model = element(withID: id) { model.setVisibility(false) }
            }
        }
    }
}
extension Messages {
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
    func update(msg: Message) { modelCache.get(msg.uid)?.update(with: msg) }
    func remove(msg: Message) {
        guard let index = indexMap[msg.uid] else { return }
        storage.remove(at: index)
        modelCache.remove(msg.uid)
        rebuildIndexMap()
        layoutAround(index)
    }
    func prepend(_ msgs: [Message]) {
        let models = msgs.map(model(for:))
        layoutBatch(models)
        storage.insert(contentsOf: models, at: 0)
        rebuildIndexMap()
    }
    func append(_ msgs: [Message]) {
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
        if let lastIndex = storage.indices.last { layoutAround(lastIndex) }
    }
    func retainNewest(_ limit: Int) async {
        guard limit >= 0, storage.count > limit else { return }
        let removeCount = storage.count - limit
        storage.removeSubrange(0..<removeCount)
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
                ? markdownFormatter.richText(for: text) : markdownFormatter.markDownText(for: text)
        }()
        let state = MsgCellViewModel.State(msg: msg, attributedText: attributedText, )
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
            let style = bubbleFactory.style(for: model.msg, previous: prev, next: next, )
            model.update(layout: style)
        }
    }
    private func layoutAround(_ index: Int) {
        guard !storage.isEmpty else { return }
        let lower = max(0, index - 1)
        let upper = min(storage.count - 1, index + 1)
        for i in lower...upper { layout(at: i) }
    }
    private func layout(at index: Int) {
        let model = storage[index]
        let prev = index > 0 ? storage[index - 1].msg : nil
        let next = index + 1 < storage.count ? storage[index + 1].msg : nil
        let style = bubbleFactory.style(for: model.msg, previous: prev, next: next, )
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
            if precedes(storage[mid].msg, msg) { low = mid + 1 } else { high = mid }
        }
        return low
    }
    private func precedes(_ lhs: Message, _ rhs: Message) -> Bool {
        if lhs.date != rhs.date { return lhs.date < rhs.date }
        return lhs.uid < rhs.uid
    }
}
extension MsgCellViewModel {
    var identified: Identified<String, MsgCellViewModel> { .init(self, id: \.id) }
}
