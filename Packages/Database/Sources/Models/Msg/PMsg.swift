//
//  PMsg.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 11/7/24.
//

import Foundation
import SwiftData
import UIKit

@Model
public final class PMsg: CollectionDocument {

	@Attribute(.unique)
	public var uid = String()
	public var senderID = String()
	public var conID = String()
	public var msgKind = Int(0)
	public var text = String()
	public var date = String()
	public var incomingStatus = MsgIncomingStatus.none.rawValue
	public var outgoingStatus = [String: MsgOutgoingStatus]()
	public var attachment: Attachment?

	public init(
		uid: String = UUID().uuidString,
		senderID: String,
		conID: String,
		msgKind: MsgKind,
		text: String,
		date: String,
		incomingStatus: MsgIncomingStatus,
		outgoingStatus: [String: MsgOutgoingStatus],
		attachment: Attachment?
	) {
		self.uid = uid
		self.senderID = senderID
		self.conID = conID
		self.msgKind = msgKind.rawValue
		self.text = text
		self.date = date
		self.incomingStatus = incomingStatus.rawValue
		self.outgoingStatus = outgoingStatus
		self.attachment = attachment
	}
}

public extension PMsg {
	func update(with snapshot: Message) {
		self.incomingStatus = snapshot.incomingStatus.rawValue
		self.outgoingStatus = snapshot.outgoingStatus
		self.attachment = snapshot.attachment
	}
	func update(with rMsg: RMsg) {
		self.incomingStatus = rMsg.incomingStatus.rawValue
		self.outgoingStatus = rMsg.outgoingStatus
		self.attachment = rMsg.attachment
	}
}
extension PMsg: SendableDocument {

	public typealias SendableType = Message

	public convenience init(from snapshot: SendableType) {
		self.init(
			uid: snapshot.uid,
			senderID: snapshot.senderID,
			conID: snapshot.conID,
			msgKind: snapshot.msgKind,
			text: snapshot.text,
			date: ServerTime(snapshot.date).value,
			incomingStatus: snapshot.incomingStatus,
			outgoingStatus: snapshot.outgoingStatus,
			attachment: snapshot.attachment
		)
	}

	public func toSendable() -> Message {
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
