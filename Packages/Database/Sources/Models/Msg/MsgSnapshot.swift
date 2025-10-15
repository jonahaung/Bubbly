//
//  MsgSnapshot.swift
//  Models
//
//  Created by Aung Ko Min on 12/7/25.
//
import Foundation
import SwiftData

public struct MsgSnapshot: Codable, Sendable, Hashable, UIdentifiable {

	public var uid: String
	public var senderID: String
	public var conID: String
	public var msgKind: MsgKind
	public var text: String
	public var date: Date
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
public extension MsgSnapshot {
	var receiptType: MsgRecipient {
		senderID == currentUserId
			? .send
			: .receive
	}
	var isSender: Bool {
		senderID == currentUserId
	}
}

extension PMsg: SendableDocument {

	public typealias SendableType = MsgSnapshot

	public convenience init(from snapshot: SendableType) {
		self.init(
			uid: snapshot.uid,
			senderID: snapshot.senderID,
			conID: snapshot.conID,
			msgKind: snapshot.msgKind,
			text: snapshot.text,
			date: ServerTime(snapshot.date),
			incomingStatus: snapshot.incomingStatus,
			outgoingStatus: snapshot.outgoingStatus,
			attachment: snapshot.attachment
		)
	}

	public func toSendable() -> MsgSnapshot {
		return SendableType(
			uid: uid,
			senderID: senderID,
			conID: conID,
			msgKind: .init(rawValue: msgKind) ?? .text,
			text: text,
			date: ServerTime(date).date,
			incomingStatus: .init(rawValue: incomingStatus) ?? .none,
			outgoingStatus: outgoingStatus,
			attachment: attachment
		)
	}
}
