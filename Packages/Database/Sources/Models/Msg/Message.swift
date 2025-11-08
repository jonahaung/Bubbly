//
//  MsgSnapshot.swift
//  Models
//
//  Created by Aung Ko Min on 12/7/25.
//
import Foundation
import SwiftData
import CoreImage
import Core

public struct Message: Codable, Sendable, Hashable, UIdentifiable {

	public let uid: String
	public let senderID: String
	public let conID: String
	public let msgKind: MsgKind
	public let text: String
	public let date: Date
	public var incomingStatus: MsgIncomingStatus
	public var outgoingStatus = [String: MsgOutgoingStatus]()
	public var attachment: Attachment?

	public init(
		uid: String,
		senderID: String,
		conID: String,
		msgKind: MsgKind,
		text: String,
		date: Date,
		incomingStatus: MsgIncomingStatus,
		outgoingStatus: [String: MsgOutgoingStatus],
		attachment: Attachment?
	) {
		self.uid = uid
		self.senderID = senderID
		self.conID = conID
		self.msgKind = msgKind
		self.text = text
		self.date = date
		self.incomingStatus = incomingStatus
		self.outgoingStatus = outgoingStatus
		self.attachment = attachment
	}
	public init(_ rMsg: RMsg) {
		self.init(
			uid: rMsg.uid,
			senderID: rMsg.senderID,
			conID: rMsg.conID,
			msgKind: rMsg.msgKind,
			text: rMsg.text,
			date: ServerTime(rMsg.date).date,
			incomingStatus: rMsg.incomingStatus,
			outgoingStatus: rMsg.outgoingStatus,
			attachment: rMsg.attachment
		)
	}
}
public extension Message {
	var receiptType: MsgRecipient {
		senderID == currentUserId
			? .send
			: .receive
	}
	var isSender: Bool {
		senderID == currentUserId
	}
}
