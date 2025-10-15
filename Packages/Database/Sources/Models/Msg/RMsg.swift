//
//  RMsg.swift
//  Models
//
//  Created by Aung Ko Min on 25/5/25.
//

import Foundation
import XUI

public struct RMsg: Codable, Conformable {

	public var uid: String
	public var conID: String
	public var msgKind: MsgKind
	public var senderID: String
	public var date: String
	public var text: String
	public var incomingStatus: MsgIncomingStatus
	public var outgoingStatus = [String: MsgOutgoingStatus]()
	public var attachment: Attachment?

	public init(
		uid: String,
		conID: String,
		msgKind: MsgKind,
		senderID: String,
		date: ServerTime,
		text: String,
		incomingStatus: MsgIncomingStatus,
		outgoingStatus: [String: MsgOutgoingStatus],
		attachment: Attachment?
	) {
		self.uid = uid
		self.conID = conID
		self.msgKind = msgKind
		self.senderID = senderID
		self.date = date.value
		self.text = text
		self.incomingStatus = incomingStatus
		self.outgoingStatus = outgoingStatus
		self.attachment = attachment
	}

	public init(_ msg: MsgSnapshot) {
		var attachment = msg.attachment
		attachment?.data = nil
		attachment?.thumbnailData = nil
		self.init(
			uid: msg.uid,
			conID: msg.conID,
			msgKind: msg.msgKind,
			senderID: msg.senderID,
			date: .init(msg.date),
			text: msg.text,
			incomingStatus: msg.incomingStatus,
			outgoingStatus: msg.outgoingStatus,
			attachment: attachment
		)
	}
	public init(msg: MsgSnapshot) {
		self.init(
			uid: msg.uid,
			conID: msg.conID,
			msgKind: msg.msgKind,
			senderID: msg.senderID,
			date: .init(msg.date),
			text: msg.text,
			incomingStatus: msg.incomingStatus,
			outgoingStatus: msg.outgoingStatus,
			attachment: msg.attachment
		)
	}

	public func serialized() -> Self {
		var copy = self
		copy.attachment?.data = nil
		copy.attachment?.thumbnailData = nil
		return copy
	}
}
