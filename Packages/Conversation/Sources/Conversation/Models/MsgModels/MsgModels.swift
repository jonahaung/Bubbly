// © 2026 Aung Ko Min

import Core
import Database
import Foundation
import Services
import SwiftUI
import XUI

// MARK: - MsgModels

@MainActor
final class MsgModels: Sendable {
	

	init(_ msgs: [Message] = [], _ headerModels: [HeaderModel] = []) {
		self.headerModels = headerModels
		richTextEnabled = UserDefaults.group.bool(forKey: GroupStorageKey.conversation(.richTextEnabled).value)
		storage = msgs.map { msg in
			model(for: msg)
		}
		evictLayoutsIfNeeded()
	}

	deinit {
		log("deinit")
	}

	
	var headerModels = [HeaderModel]()

	

	private var storage = [MsgCellViewModel]()
	private let bubbleFactory = BubbleFactory()
    private var modelCache = LRUCache<MsgCellViewModel.ID, MsgCellViewModel>()
	private let markdownFormatter = MarkdownFormatter()
	private let richTextEnabled: Bool
}

extension MsgModels {
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
		storage
	}

	func contains(withID id: String) -> Bool {
		index(of: id) != nil
	}

	func index(of id: String) -> Int? {
		storage.firstIndex(where: { $0.id == id })
	}

	subscript(position: Int) -> MsgCellViewModel? {
		storage[safe: position]
	}

	subscript(safe position: Int) -> MsgCellViewModel? {
		storage[safe: position]
	}

	func element(withID id: String) -> MsgCellViewModel? {
        storage.first(where: { $0.id == id })
    }
}

extension MsgModels {
    func didBecomeVisible(ids: [String]) {
        let oldIDs = storage.filter{ $0.isVisible }.map(\.id)
        let difference = ids.difference(from: oldIDs)
        
        difference.forEach { each in
            switch each {
            case let .insert(_, element, _):
                didChangeVisibility(for: element, isVisible: true)
            case let .remove(_, element, _):
                didChangeVisibility(for: element, isVisible: false)
            }
        }
    }
	func didChangeVisibility(for id: String, isVisible: Bool) {
		element(withID: id)?.setVisibility(isVisible)
	}

	func didChangeSelection(_ selectedMsg: SelectedMsg?, for id: String) {
		element(withID: id)?.update(selectedMsg: selectedMsg)
	}

	func model(for msg: Message) -> MsgCellViewModel {
		if let cached = modelCache.get(msg.uid) {
			return cached
		}
		let attributedText: AttributedString? = {
			if let text = msg.text {
				return richTextEnabled ? markdownFormatter
					.richText(for: text) : markdownFormatter
					.markDownText(for: text)
			}
			return nil
		}()
		let state = MsgCellViewModel.State(msg: msg, attributedText: attributedText)
		let model = MsgCellViewModel(state)
		modelCache.set(msg.uid, value: model)
		return model
	}

	func set(msgs: [Message]) {
		storage = msgs.map { msg in
			model(for: msg)
		}
		evictLayoutsIfNeeded()
	}

	func insert(msg: Message) {
		let index = insertionIndex(for: msg)
		let model = model(for: msg)
		storage.insert(model, at: index)
		invalidateLayoutsForUpdate(at: index)
	}

	func update(msg: Message) {
		modelCache.get(msg.uid)?.update(with: msg)
	}

	func remove(msg: Message) {
		guard let removedIndex = index(of: msg.uid) else {
			return
		}

		storage.removeAll(where: { $0.id == msg.id })

		modelCache.remove(msg.uid)
		invalidateLayoutsAround(index: removedIndex)
	}

	func prepend(_ msgs: [Message]) async {
        let models = msgs.map { model(for: $0) }
        models.filter{ $0.state.layout.isEmpty }.forEach { layout(for: $0.id, models: models) }
		storage.insert(contentsOf:  models, at: 0)
	}

	func append(_ msgs: [Message]) async {
        let models = msgs.map { model(for: $0) }
        models.filter{ $0.state.layout.isEmpty }.forEach { layout(for: $0.id, models: models) }
		storage.append(contentsOf: models)
	}

	func retainOldest(_ limit: Int) async {
		guard limit >= 0 else {
			return
		}

		guard storage.count > limit else {
			return
		}

		storage.removeSubrange(limit ..< storage.count)
        layout(for: count-1)
	}

	func retainNewest(_ limit: Int) async {
		guard limit >= 0 else {
			return
		}

		guard storage.count > limit else {
			return
		}

		let removeCount = storage.count - limit
		storage.removeSubrange(0 ..< removeCount)
        layout(for: 0)
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
			storage[index].update(layout: .init())
		}
	}

    private func layout(for id: String, models: [MsgCellViewModel]) {
        guard let index = models.firstIndex(where: { $0.id == id }) else {
            return
        }
        layout(for: index, models: models)
    }
    private func layout(for index: Int, models: [MsgCellViewModel]) {
        let model = models[index]
        let prevMsg = index > 0 ? models[index - 1].msg : nil
        let nextMsg = index + 1 < models.count ? models[index + 1].msg : nil
        let style = bubbleFactory.style(for: models[index].msg, previous: prevMsg, next: nextMsg)
        model.update(layout: style)
    }
    
	private func layout(for id: String) {
		guard let index = index(of: id) else {
			return
		}
        layout(for: index)
	}
    private func layout(for index: Int) {
        let model = storage[index]
        let prevMsg = index > 0 ? storage[index - 1].msg : nil
        let nextMsg = index + 1 < storage.count ? storage[index + 1].msg : nil
        let style = bubbleFactory.style(for: storage[index].msg, previous: prevMsg, next: nextMsg)
        model.update(layout: style)
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
