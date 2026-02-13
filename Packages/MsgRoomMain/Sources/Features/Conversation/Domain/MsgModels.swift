import Database
import Services
import SwiftUI
import XUI

@MainActor
@Observable
public final class MsgModels {
	public typealias MsgID = Message.UID
	@ObservationIgnored private var modelCache = [MsgID: MsgCellViewModel]()
	@ObservationIgnored private var styleCache = [MsgID: MsgCellLayout]()
	@ObservationIgnored private var bubbleFactory = BubbleFactory()

	var ids = [MsgID]()

	init(_ msgs: [Message] = []) {
		set(msgs: msgs, forceReset: false)
	}
}

public extension MsgModels {
	var count: Int {
		ids.count
	}

	var first: MsgCellViewModel? {
		guard let id = ids.first else {
			return nil
		}
		return cached(for: id)
	}

	var last: MsgCellViewModel? {
		guard let id = ids.last else {
			return nil
		}
		return cached(for: id)
	}

	var isEmpty: Bool {
		ids.isEmpty
	}

	func contains(withID id: MsgID) -> Bool {
		ids.contains(where: { $0 == id })
	}

	func index(of id: MsgID) -> Int? {
		ids.firstIndex(where: { $0 == id })
	}

	subscript(position: Int) -> MsgCellViewModel? {
		cached(for: ids[position])
	}

	subscript(safe position: Int) -> MsgCellViewModel? {
		ids.indices.contains(position) ? self[position] : nil
	}

	func element(withID id: MsgID) -> MsgCellViewModel? {
		cached(for: id)
	}

	func msgs() -> [Message] {
		ids.compactMap { self.cached(for: $0)?.msg }
	}
}

public extension MsgModels {
	func cached(for id: MsgID) -> MsgCellViewModel? {
		modelCache[id]
	}

	func model(for msg: Message) -> MsgCellViewModel {
		if let cached = cached(for: msg.uid) {
			return cached
		}
		let model = MsgCellViewModel(msg)
		modelCache[msg.uid] = model
		return model
	}

	func style(for id: MsgID) -> MsgCellLayout? {
		styleCache[id]
	}

	func set(msgs: [Message], forceReset: Bool) {
		var models = forceReset ? [] : ids.compactMap { self.cached(for: $0) }
		var existingIDs = Set(models.map(\.msg.uid))
		for msg in msgs {
			if let cached = cached(for: msg.uid) {
				cached.update(with: msg)
				if let existingIndex = models.firstIndex(where: { $0.msg.uid == msg.uid }) {
					models.remove(at: existingIndex)
				}
				let index = models.insertionIndex(for: cached, by: \.msg.date)
				models.insert(cached, at: index)
				existingIDs.insert(msg.uid)
			} else {
				let model = model(for: msg)
				let index = models.insertionIndex(for: model, by: \.msg.date)
				models.insert(model, at: index)
				existingIDs.insert(msg.uid)
			}
		}
		rebuildLayouts(models: models)
		ids = models.map(\.msg.uid)
	}

	func updateBubble(for msg: Message, msgs: [Message]) -> MsgCellLayout {
		guard let index = msgs.firstIndex(of: msg) else { return .init() }
		let prevMsg = msgs[safe: index - 1]
		let nextMsg = msgs[safe: index + 1]

		let style = bubbleFactory.style(for: msg, previous: prevMsg, next: nextMsg)
		styleCache[msg.uid] = style
		return style
	}

	func insert(msg: Message) {
		let index = insertionIndex(for: msg)
		let model = model(for: msg)

		let prevMsg: Message? = {
			guard let id = ids[safe: index - 1] else { return nil }
			return self.cached(for: id)?.msg
		}()

		let nextMsg: Message? = {
			guard let id = ids[safe: index + 1] else { return nil }
			return self.cached(for: id)?.msg
		}()

		let style = bubbleFactory.style(for: msg, previous: prevMsg, next: nextMsg)
		styleCache[msg.uid] = style

		if let prevMsg {
			let prevMsg2: Message? = {
				guard let id = ids[safe: index - 2] else { return nil }
				return self.cached(for: id)?.msg
			}()

			let prevModel = self.model(for: prevMsg)
			let prevStyle = bubbleFactory.style(for: prevMsg, previous: prevMsg2, next: msg)
			styleCache[prevMsg.uid] = prevStyle
			prevModel.update(layout: prevStyle)
		}

		if let nextMsg {
			let nextMsg2: Message? = {
				guard let id = ids[safe: index + 2] else { return nil }
				return self.cached(for: id)?.msg
			}()
			let nextModel = self.model(for: nextMsg)
			let nextStyle = bubbleFactory.style(for: nextMsg, previous: msg, next: nextMsg2)
			styleCache[nextMsg.uid] = nextStyle
			nextModel.update(layout: nextStyle)
		}
		model.update(layout: style)
		ids.insert(msg.uid, at: index)
	}

	func insertionIndex(for id: MsgID,
	                    by keyPath: KeyPath<MsgID, some Comparable>) -> Int
	{
		ids.insertionIndex(for: id, by: keyPath)
	}

	func insertionIndex(for msg: Message) -> Int {
		ids.firstIndex { id in
			guard let existing = cached(for: id) else { return false }
			return existing.msg.date > msg.date
		} ?? ids.count
	}

	func takingPrefix(_ count: Int) {
		guard count > 0 else { return }
		ids = Array(ids.prefix(count))
	}

	func takingSuffix(_ count: Int) {
		guard count > 0 else { return }
		ids = Array(ids.suffix(count))
	}

	func update(msg: Message) {
		guard let model = cached(for: msg.uid) else { return }
		model.update(with: msg)
		guard let index = ids.firstIndex(where: { $0 == msg.uid }) else { return }
		refreshLayout(at: index)
	}

	func remove(msg: Message) {
		guard let index = ids.firstIndex(where: { $0 == msg.uid }) else { return }
		ids.remove(at: index)
		modelCache[msg.uid] = nil
		styleCache[msg.uid] = nil
		refreshLayout(at: index - 1)
		refreshLayout(at: index)
	}
}

private extension MsgModels {
	func rebuildLayouts(models: [MsgCellViewModel]) {
		let messages = models.map(\.msg)
		for (index, model) in models.enumerated() {
			if style(for: model.id) == nil {
				let prevMsg = messages[safe: index - 1]
				let nextMsg = messages[safe: index + 1]
				let style = bubbleFactory.style(for: model.msg, previous: prevMsg, next: nextMsg)
				styleCache[model.msg.uid] = style
				model.update(layout: style)
			}
		}
	}

	func refreshLayout(at index: Int) {
		guard ids.indices.contains(index) else { return }
		guard let id = ids[safe: index],
		      let model = cached(for: id) else { return }
		let prevMsg = ids[safe: index - 1].flatMap { cached(for: $0)?.msg }
		let nextMsg = ids[safe: index + 1].flatMap { cached(for: $0)?.msg }
		let style = bubbleFactory.style(for: model.msg, previous: prevMsg, next: nextMsg)
		styleCache[model.msg.uid] = style
		model.update(layout: style)
	}
}
