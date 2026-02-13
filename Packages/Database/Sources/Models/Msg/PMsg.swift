import Foundation
import SwiftData
import UIKit

@Model
public final class PMsg: CollectionDocument {
	@Attribute(.unique)
	public var uid = String()
	public var senderID = String()
	public var conID = String()
	public var text: String?
	public var date = String()
	public var incomingStatus = MsgIncomingStatus.none.rawValue
	public var outgoingStatus = [String: MsgOutgoingStatus]()
	public var attachments = [Attachment]()
	public var reactions = [Reaction]()

	public init(uid: String = UUID().uuidString,
	            senderID: String,
	            conID: String,
	            text: String?,
	            date: String,
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
		self.incomingStatus = incomingStatus.rawValue
		self.outgoingStatus = outgoingStatus
		self.attachments = attachments
		self.reactions = reactions
	}
}

public extension PMsg {
	func update(with rMsg: RMsg) {
		incomingStatus = rMsg.incomingStatus.rawValue
		outgoingStatus = rMsg.outgoingStatus
		attachments = rMsg.attachments
		reactions = rMsg.reactions
	}

	func update(from item: Message) {
		incomingStatus = item.incomingStatus.rawValue
		outgoingStatus = item.outgoingStatus
		attachments = item.attachments
		reactions = item.reactions
	}
}

extension PMsg: SendableDocument {
	public typealias SendableType = Message

	public convenience init(from snapshot: SendableType) {
		self.init(
			uid: snapshot.uid,
			senderID: snapshot.senderID,
			conID: snapshot.conID,
			text: snapshot.text,
			date: ServerTime(snapshot.date).value,
			incomingStatus: snapshot.incomingStatus,
			outgoingStatus: snapshot.outgoingStatus,
			attachments: snapshot.attachments,
			reactions: snapshot.reactions
		)
	}

	public func toSendable() -> Message {
		SendableType(
			uid: uid,
			senderID: senderID,
			conID: conID,
			text: text,
			date: ServerTime(date).date,
			incomingStatus: .init(rawValue: incomingStatus) ?? .none,
			outgoingStatus: outgoingStatus,
			attachments: attachments,
			reactions: reactions
		)
	}
}
