// © 2026 Aung Ko Min

import Database
import Foundation
import Services
import SwiftUI
import XUI

// MARK: - MsgModels

@MainActor
final class MsgModels {
    // MARK: Lifecycle

    init(_ msgs: [Message] = [], _ headerModels: [HeaderModel] = []) {
        self.headerModels = headerModels
        storage = msgs.map { msg in
            model(for: msg).identified
        }
        evictLayoutsIfNeeded()
    }

    deinit {
        layoutCache.removeAll()
        log("deinit")
    }

    // MARK: Private

    private var storage: [Identified<String, MsgCellViewModel>] = []
    private let layoutCache: DicCache<String, MsgCellLayout> = .init()
    private let bubbleFactory: BubbleFactory = .init()
    var headerModels: [HeaderModel] = []
}

extension MsgModels {
    var count: Int {
        storage.count
    }

    var first: MsgCellViewModel? {
        storage.first?.value
    }

    var last: MsgCellViewModel? {
        storage.last?.value
    }

    var isEmpty: Bool {
        storage.isEmpty
    }

    var renderedModels: [Identified<String, MsgCellViewModel>] {
        storage
    }

    var ids: [String] {
        storage.map(\.msg.uid)
    }

    func contains(withID id: String) -> Bool {
        storage.contains(where: { $0.id == id })
    }

    func index(of id: String) -> Int? {
        storage.firstIndex(where: { $0.id == id })
    }

    subscript(position: Int) -> MsgCellViewModel? {
        storage[safe: position]?.value
    }

    subscript(safe position: Int) -> MsgCellViewModel? {
        storage[safe: position]?.value
    }

    func element(withID id: String) -> MsgCellViewModel? {
        storage.first(where: { $0.id == id })?.value
    }
}

extension MsgModels {
    func didChangeVisibility(for id: String, isVisible: Bool) {
        element(withID: id)?.setVisibility(isVisible)
    }

    func didChangeSelection(_ selectedMsg: SelectedMsg?, for id: String) {
        element(withID: id)?.update(selectedMsg: selectedMsg)
    }

    //	public func cached(for id: String) -> MsgCellViewModel? {
    //		modelCache.get(id)
    //	}

    func model(for msg: Message) -> MsgCellViewModel {
        //		if let cached = modelCache.get(msg.uid) { return cached }
        MsgCellViewModel(msg)
        //		modelCache.set(msg.uid, value: model)
    }

    func set(msgs: [Message]) {
        storage = msgs.map { msg in
            model(for: msg).identified
        }
        evictLayoutsIfNeeded()
    }

    func insert(msg: Message) {
        let index = insertionIndex(for: msg)
        let model = model(for: msg)
        storage.insert(model.identified, at: index)
        invalidateLayoutsForUpdate(at: index)
    }

    func update(msg: Message) {
        storage.first(where: { $0.id == msg.uid })?.value.update(with: msg)
        //		modelCache.get(msg.uid)?.update(with: msg)
    }

    func remove(msg: Message) {
        guard let removedIndex = index(of: msg.uid) else {
            return
        }

        storage.removeAll(where: { $0.id == msg.id })
        layoutCache.remove(msg.uid)
        invalidateLayoutsAround(index: removedIndex)
    }

    func prepend(_ msgs: [Message]) {
        storage.insert(contentsOf: msgs.map { model(for: $0).identified }, at: 0)
        evictLayoutsIfNeeded()
    }

    func append(_ msgs: [Message]) {
        storage.append(contentsOf: msgs.map { model(for: $0).identified })
        evictLayoutsIfNeeded()
    }

    func retainOldest(_ limit: Int) {
        guard limit >= 0 else {
            return
        }

        guard storage.count > limit else {
            return
        }

        storage.removeSubrange(limit ..< storage.count)
    }

    func retainNewest(_ limit: Int) {
        guard limit >= 0 else {
            return
        }

        guard storage.count > limit else {
            return
        }

        let removeCount = storage.count - limit
        storage.removeSubrange(0 ..< removeCount)
    }
}

extension MsgModels {
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
            ensureLayouts(in: lower ..< upper)
        }
    }

    private func invalidateLayoutsAround(index: Int) {
        guard !storage.isEmpty else {
            return
        }

        let lower = max(0, index - 1)
        let upper = min(storage.count - 1, index + 1)
        if lower > upper {
            return
        }
        for index in lower ... upper {
            layoutCache.remove(storage[index].id)
        }
    }

    private func layout(for id: String) {
        guard let index = index(of: id) else {
            return
        }

        if let cached = layoutCache.get(id) {
            storage[index].value.update(layout: cached)
            return
        }
        let prevMsg = index > 0 ? storage[index - 1].msg : nil
        let nextMsg = index + 1 < storage.count ? storage[index + 1].msg : nil
        let style = bubbleFactory.style(for: storage[index].msg, previous: prevMsg, next: nextMsg)
        layoutCache.set(id, value: style)
        storage[index].value.update(layout: style)
    }

    private func ensureLayouts(in range: Range<Int>) {
        guard !range.isEmpty else {
            return
        }

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

extension MsgCellViewModel {
    var identified: Identified<String, MsgCellViewModel> {
        .init(self, id: \.id)
    }
}
