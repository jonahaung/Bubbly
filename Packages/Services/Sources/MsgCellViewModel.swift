//
//  MsgCellViewModel.swift
//  Services
//
//  Created by Aung Ko Min on 14/8/25.
//

import Database
import SwiftUI
import XUI

@Observable
public final class MsgCellViewModel: ViewReloadable {
	public struct ContentRenderKey: Hashable {
		public let id: String
		public let text: String?
		public let attachments: [Attachment]
		public let isSelected: Bool
		public let reactions: [Reaction]
		public let isVisible: Bool
	}

	public var msg: Message
	public private(set) var isVisible = false
	public private(set) var layout = MsgCellLayout()
	public var reloadID: Int = 0
	public var animationTrigger: Int = 0

	public var contentRenderKey: ContentRenderKey

	public init(_ msg: Message) {
		self.msg = msg
		contentRenderKey = .init(
			id: msg.uid,
			text: msg.text,
			attachments: msg.attachments,
			isSelected: false,
			reactions: msg.reactions,
			isVisible: false
		)
	}

	public func update(with msg: Message) {
		guard self.msg != msg else { return }
		self.msg = msg
		layoutIfNeeded()
	}

	public func update(layout: MsgCellLayout) {
		guard self.layout != layout else { return }
		self.layout = layout
		layoutIfNeeded()
	}

	public func setVisibility(_ isVisible: Bool) {
		guard self.isVisible != isVisible else { return }
		self.isVisible = isVisible
	}

	public func animate() {
		animationTrigger += 1
	}

	func recomputeRenderKey(selectedMsg: SelectedMsg?,
	                        layout: MsgCellLayout)
	{
		let isSelected = (selectedMsg?.id == id)
		contentRenderKey = ContentRenderKey(
			id: id,
			text: msg.text,
			attachments: msg.attachments,
			isSelected: isSelected,
			reactions: msg.reactions,
			isVisible: isVisible
		)
	}

	func computeBubbleCOrner(selectedMsg: SelectedMsg?, isSender: Bool) -> BubbleCorner {
		guard let selectedMsg else {
			return layout.bubbleCorner
		}
		let isSelected = selectedMsg.id == id
		if isSelected {
			return .all
		}
		var corner = layout.bubbleCorner

		if selectedMsg.previous == id {
			corner.append(.bottom)
			return corner
		}
		if selectedMsg.next == id {
			corner.append(.top)
			return corner
		}
		return corner
	}
}

public extension MsgCellViewModel {
	var id: String {
		msg.uid
	}

	var isSender: Bool {
		msg.isSender
	}

	var foregroundStyle: Color {
		isSender ? .black : .primary
	}

	var horizontalAlignment: HorizontalAlignment {
		isSender ? .trailing : .leading
	}
	var verticalAlignment: VerticalItemAlignment {
		isSender ? .trailing : .leading
	}
	func sender() -> Contact? {
		ContactStore.shared.contact(for: msg.senderID)
	}
}

public extension HorizontalAlignment {
	var inverted: HorizontalAlignment {
		self == .leading ? .trailing : .leading
	}
}
public enum VerticalItemAlignment: Sendable {
	case leading
	case trailing
}
