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

	public var uid = String()
	public var senderID = String()
	public var conID = String()
	public var msgKind = Int(0)
	public var text = String()
	public var date = String()
	public var incomingStatus = MsgIncomingStatus.none.rawValue
	public var outgoingStatus = [String: MsgOutgoingStatus]()
	@Attribute(.externalStorage) public var attachment: Attachment?

	public init(
		uid: String = UUID().uuidString,
		senderID: String,
		conID: String,
		msgKind: MsgKind,
		text: String,
		date: ServerTime,
		incomingStatus: MsgIncomingStatus,
		outgoingStatus: [String: MsgOutgoingStatus],
		attachment: Attachment?
	) {
		self.uid = uid
		self.senderID = senderID
		self.conID = conID
		self.msgKind = msgKind.rawValue
		self.text = text
		self.date = date.value
		self.incomingStatus = incomingStatus.rawValue
		self.outgoingStatus = outgoingStatus
		self.attachment = attachment
	}
}

extension PMsg {
	public func update(with snapshot: MsgSnapshot) {
		self.incomingStatus = snapshot.incomingStatus.rawValue
		self.outgoingStatus = snapshot.outgoingStatus
		self.attachment = snapshot.attachment
	}
	public func update(with rMsg: RMsg) {
		self.incomingStatus = rMsg.incomingStatus.rawValue
		self.outgoingStatus = rMsg.outgoingStatus
		self.attachment = rMsg.attachment
	}
}
