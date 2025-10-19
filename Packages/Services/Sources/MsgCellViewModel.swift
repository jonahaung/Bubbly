//
//  MsgCellViewModel.swift
//  Services
//
//  Created by Aung Ko Min on 14/8/25.
//

import SwiftUI
import Database
import XUI

@Observable
public final class MsgCellViewModel: @unchecked Sendable {

	public let id: String
	public let isSender: Bool
	public var msg: MsgSnapshot
	public var displayData: MsgCellDisplayData
	public var canObserveFocusedFrame = false
	public var msgID: String { id }

	public init(_ msg: MsgSnapshot) {
		self.msg = msg
		self.id = msg.uid
		self.isSender = msg.isSender
		self.displayData = .init(msg: msg)
	}
	public func update(with msg: MsgSnapshot) {
		guard self.msg != msg else { return }
		self.msg = msg
		self.displayData.content = MsgCellDisplayData.ContentDisplay.create(from: msg)
	}

	public func onAppear() {

	}
	public func onDisappear() {

	}
	public func prefetch() {

	}
	public func cancelPrefetch() {
		
	}
}

public extension MsgCellViewModel {
	var foregroundStyle: Color {
		isSender ? .black : .primary
	}
	var horizontalAlignment: HorizontalAlignment {
		isSender ? .trailing : .leading
	}
	@MainActor func sender() -> ContactSnapshot? {
		ContactStore.shared.contact(for: msg.senderID)
	}
}
