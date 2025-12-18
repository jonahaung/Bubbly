import Database
import Foundation
import Services
import UIKit
import XUI

public actor MsgCreator {
	// MARK: - Errors

	public enum Error: Swift.Error {
		case noCurrentUserId
		case imageProcessingFailed(Swift.Error? = nil)
		case dataConversionFailed
	}

	// MARK: - Dependencies

	private let mediaManager: MediaManager
	private let currentUserId: String

	// MARK: - Init

	public init(currentUserId: String, mediaManager: MediaManager = .shared) {
		self.mediaManager = mediaManager
		self.currentUserId = currentUserId
	}

	// MARK: - ✅ Public APIs

	public func create(text: String, link: URL? = nil, in conversation: Conversation) async throws -> Message {
		var attachment: Attachment?
		let msgID = Self.generateMessageId()

		if let link {
			let linkData = try await LinkData.performFetch(for: link)
			if let image = linkData.image {
				let aspectRatio = image.size.width / max(image.size.height, 1)
				attachment = .init(
					uid: msgID,
					url: link.absoluteString,
					attachMentTypeRaw: AttachMentType.link.rawValue,
					aspectRatio: aspectRatio
				)
			}
		}
		return Message(
			uid: msgID,
			senderID: currentUserId,
			conID: conversation.uid,
			msgKind: .text,
			text: text,
			date: .now,
			incomingStatus: .none,
			outgoingStatus: makeOutgoingStatus(for: conversation),
			attachment: attachment
		)
	}

	public func create(
		from url: URL,
		in conversation: Conversation
	) async throws -> Message {
		let linkData = try await LinkData.performFetch(for: url)

		guard let image = linkData.image else {
			return try await create(text: url.absoluteString, in: conversation)
		}

		return try await createImageMessage(
			image: image,
			text: linkData.description,
			urlString: url.absoluteString,
			type: .link,
			in: conversation
		)
	}

	public func create(
		from image: UIImage,
		in conversation: Conversation
	) async throws -> Message {
		try await createImageMessage(
			image: image,
			text: "Image",
			urlString: "",
			type: .imageUploading,
			in: conversation
		)
	}
}

// MARK: - Private Actor Methods

private extension MsgCreator {
	// MARK: - Message Building

	func createImageMessage(
		image: UIImage,
		text: String,
		urlString: String,
		type: AttachMentType,
		in conversation: Conversation
	) async throws -> Message {
		let id = Self.generateMessageId()

		var message = Message(
			uid: id,
			senderID: currentUserId,
			conID: conversation.uid,
			msgKind: .attachment,
			text: text,
			date: .now,
			incomingStatus: .none,
			outgoingStatus: makeOutgoingStatus(for: conversation),
			attachment: Attachment(uid: id, url: urlString, attachMentTypeRaw: type.rawValue, aspectRatio: 1)
		)

		let updatedAttachment = try await processImageAttachment(
			for: message,
			original: image,
			type: type,
			url: urlString
		)
		message.attachment = updatedAttachment

		return message
	}

	// MARK: - ✅ Background-safe image & file processing

	func processImageAttachment(
		for message: Message,
		original image: UIImage,
		type: AttachMentType,
		url: String
	) async throws -> Attachment {
		do {
			// Image encoding happens inside this actor (safe)
			let imageData = try mediaManager.createData(from: image)
			let thumbnailData = try await mediaManager.createThumbnail(from: image)

			guard let thumbnailImage = UIImage(data: thumbnailData) else {
				throw Error.dataConversionFailed
			}

			let aspectRatio = thumbnailImage.size.width / max(thumbnailImage.size.height, 1)

			// ✅ Move heavy file I/O off the MainActor/actor to a background queue
			try await Task.detached(priority: .utility) {
				try message.file()?.write(imageData)
				try message.thumbnailFile()?.write(thumbnailData)
			}.value

			return Attachment(
				uid: message.uid,
				url: url,
				attachMentTypeRaw: type.rawValue,
				aspectRatio: aspectRatio
			)

		} catch {
			throw Error.imageProcessingFailed(error)
		}
	}

	// MARK: - Outgoing Status

	func makeOutgoingStatus(
		for conversation: Conversation
	) -> [String: MsgOutgoingStatus] {
		var dict = [String: MsgOutgoingStatus]()
		dict.reserveCapacity(conversation.members.count)
		for member in conversation.members where member != currentUserId {
			dict[member] = .sending
		}
		return dict
	}
}

// MARK: - nonisolated Utilities

private extension MsgCreator {
	nonisolated static func generateMessageId() -> String {
		UUID().uuidString.lowercased()
	}
}
