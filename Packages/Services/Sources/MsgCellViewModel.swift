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

	public var msg: Message
	public private(set) var isVisible = false
	public private(set) var layout = MsgCellLayout()
	public var reloadID: Int = 0
	public var animationTrigger: Int = 0

	public init(_ msg: Message) {
		self.msg = msg
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
}

public extension MsgCellViewModel {
	var id: String { msg.uid }
	var isSender: Bool { msg.isSender }
	var foregroundStyle: Color {
		isSender ? .black : .primary
	}

	var horizontalAlignment: HorizontalAlignment {
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
