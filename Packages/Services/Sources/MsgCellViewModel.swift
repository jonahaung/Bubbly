//
//  MsgCellViewModel.swift
//  Services
//
//  Created by Aung Ko Min on 14/8/25.
//

import SwiftUI
import Database
import XUI

@MainActor
@Observable
public final class MsgCellViewModel: Sendable {

	public let id: String
	public let isSender: Bool
	public var msg: Message
	public var displayData: MsgCellDisplayData
	public var msgID: String { id }
	public private(set) var isVisible = false
	public let attachment: MsgCellAttachmentViewModel = .init()

	public init(_ msg: Message) {
		self.msg = msg
		self.id = msg.uid
		self.isSender = msg.isSender
		self.displayData = .init(msg: msg)
	}
	public func update(with msg: Message) {
		guard self.msg != msg else { return }
		self.msg = msg
		self.displayData.content = MsgCellDisplayData.ContentDisplay.create(from: msg)
	}

	public func setVisibility(_ isVisible: Bool) {
		guard self.isVisible != isVisible else { return }
		self.isVisible = isVisible
	}
}

public extension MsgCellViewModel {
	var foregroundStyle: Color {
		isSender ? .black : .primary
	}
	var horizontalAlignment: HorizontalAlignment {
		isSender ? .trailing : .leading
	}
	@MainActor func sender() -> Contact? {
		ContactStore.shared.contact(for: msg.senderID)
	}
}

@MainActor
@Observable
public final class MsgCellAttachmentViewModel {
	public var thumbnail: UIImage?
}
