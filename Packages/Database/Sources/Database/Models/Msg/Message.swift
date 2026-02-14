//
//  MsgSnapshot.swift
//  Models
//
//  Created by Aung Ko Min on 12/7/25.
//
import Core
import CoreImage
import Foundation
import SwiftData

public struct Message: Codable, Sendable, Hashable, UIdentifiable {
	public let uid: String
	public let senderID: String
	public let conID: String
	public var text: String?
	public let date: Date
	public var incomingStatus: MsgIncomingStatus
	public var outgoingStatus = [String: MsgOutgoingStatus]()
	public var attachments: [Attachment]
	public var reactions: [Reaction]

	public init(uid: String,
	            senderID: String,
	            conID: String,
	            text: String?,
	            date: Date,
	            incomingStatus: MsgIncomingStatus,
	            outgoingStatus: [String: MsgOutgoingStatus],
	            attachments: [Attachment],
	            reactions: [Reaction])
	{
		self.uid = uid
		self.senderID = senderID
		self.conID = conID
		self.text = text
		self.date = date
		self.incomingStatus = incomingStatus
		self.outgoingStatus = outgoingStatus
		self.attachments = attachments
		self.reactions = reactions
	}

	public init(_ rMsg: RMsg) {
		self.init(
			uid: rMsg.uid,
			senderID: rMsg.senderID,
			conID: rMsg.conID,
			text: rMsg.text,
			date: ServerTime(rMsg.date).date,
			incomingStatus: rMsg.incomingStatus,
			outgoingStatus: rMsg.outgoingStatus,
			attachments: rMsg.attachments,
			reactions: rMsg.reactions
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

public extension Message {
	var displayText: String {
		guard let text, !text.isWhitespace else {
			return attachments.first?.displayText ?? ""
		}
		return text
	}
}
