//
//  MsgCreater.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 11/10/25.
//

import UIKit
import Database
import Services
import Foundation
import XUI

public struct MsgCreater: Sendable {

	enum Error: Swift.Error {
		case noCurrentUserId
	}

	func create(text: String, _ conversation: ConversationSnapshot) throws -> MsgSnapshot {
		guard let currentUserId else { throw Self.Error.noCurrentUserId }
		let msg = MsgSnapshot(
			uid: UUID().uuidString.lowercased(),
			senderID: currentUserId,
			conID: conversation.uid,
			msgKind: .text,
			text: text,
			date: .now,
			incomingStatus: .none,
			outgoingStatus: try getOutgoingStatus(for: conversation),
			attachment: nil
		)
		return msg
	}

	func create(url: URL, _ conversation: ConversationSnapshot) async throws -> MsgSnapshot {
		guard let currentUserId else { throw Self.Error.noCurrentUserId }
		if let image = try await LinkData.performFetch(for: url).image {
			let attachment = try await attachment(for: image, type: .link, url: url.absoluteString)
			let msg = MsgSnapshot(
				uid: attachment.uid,
				senderID: currentUserId,
				conID: conversation.uid,
				msgKind: .attachment,
				text: url.absoluteString,
				date: .now,
				incomingStatus: .none,
				outgoingStatus: try getOutgoingStatus(for: conversation),
				attachment: attachment
			)
			return msg
		}
		return try create(text: url.absoluteString, conversation)
	}

	func create(image: UIImage, _ conversation: ConversationSnapshot) async throws -> MsgSnapshot {
		guard let currentUserId else { throw Self.Error.noCurrentUserId }

		let attachment = try await attachment(for: image, type: .imageUploading, url: .init())
		let msg = MsgSnapshot(
			uid: attachment.uid,
			senderID: currentUserId,
			conID: conversation.uid,
			msgKind: .attachment,
			text: attachment.attachmentType.description,
			date: .now,
			incomingStatus: .none,
			outgoingStatus: try getOutgoingStatus(for: conversation),
			attachment: attachment
		)
		return msg
	}
}

private extension MsgCreater {
	func getOutgoingStatus(for conversation: ConversationSnapshot) throws -> [String: MsgOutgoingStatus] {
		guard let currentUserId else { throw Self.Error.noCurrentUserId }
		var outgoinStatus = [String: MsgOutgoingStatus]()
		conversation.members.filter{ $0 != currentUserId }.forEach { each in
			outgoinStatus[each] = .sending
		}
		return outgoinStatus
	}
	func attachment(for image: UIImage, type: MsgAttachment.AttachMentType, url: String) async throws -> Attachment {
		let mediaManager = MediaManager.shared
		let data = try mediaManager.createData(from: image)
		let thumbnilData = try await mediaManager.createThumbnil(from: image)

		let msgID = UUID().uuidString.lowercased()
		let thumbnil = UIImage(data: thumbnilData)!
		let aspectRatio = thumbnil.size.width / thumbnil.size.height

		let attachment = Attachment(
			uid: msgID,
			url: url,
			attachMentTypeRaw: type.rawValue,
			aspectRatio: aspectRatio,
			data: data,
			thumbnailData: thumbnilData
		)
		return attachment
	}
}
