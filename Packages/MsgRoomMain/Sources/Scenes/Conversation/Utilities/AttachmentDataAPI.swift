//
//  AttachmentDataAPI.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 20/10/25.
//

import UIKit
import XUI
import Database
import Services
import UniformTypeIdentifiers
import LinkPresentation

actor AttachmentDataAPI {

	// MARK: - Errors
	enum AttachmentError: LocalizedError {
		case missingImageID
		case invalidURL(String)
		case imageDecodingFailed
		case thumbnailCreationFailed
		case fileWriteFailed(Error)
		case invalidAttachmentState(AttachMentType)
		case missingLinkImage

		var errorDescription: String? {
			switch self {
			case .missingImageID:
				return "Message is missing image ID"
			case .invalidURL(let urlString):
				return "Invalid URL: \(urlString)"
			case .imageDecodingFailed:
				return "Failed to decode image data"
			case .thumbnailCreationFailed:
				return "Failed to create thumbnail"
			case .fileWriteFailed(let error):
				return "Failed to write file: \(error.localizedDescription)"
			case .invalidAttachmentState(let type):
				return "Invalid attachment state: \(type)"
			case .missingLinkImage:
				return "Link preview image is missing"
			}
		}
	}

	// MARK: - Dependencies
	private let mediaManager: MediaManager
	private let urlSession: URLSession

	// MARK: - Initialization
	init(mediaManager: MediaManager = .shared, urlSession: URLSession = .shared) {
		self.mediaManager = mediaManager
		self.urlSession = urlSession
	}

	// MARK: - Public Interface
	func fetchAttachmentData(for message: Message) async throws -> AttachmentData {
		guard let id = message.imageID else {
			throw AttachmentError.missingImageID
		}

		// Early return if no attachment exists
		guard let attachment = message.attachment else {
			return AttachmentData(id: id, data: nil)
		}

		// Try to use cached images first
		if let cachedData = try getCachedImageData(for: message) {
			return AttachmentData(id: id, data: cachedData)
		}

		// Process based on attachment type
		let thumbnailData = try await processAttachment(attachment, for: message)
		return AttachmentData(id: id, data: thumbnailData)
	}
}

// MARK: - Private Implementation
private extension AttachmentDataAPI {

	// MARK: - Cached Image Handling
	func getCachedImageData(for message: Message) throws -> Data? {
		if let image = message.thumbnailImage() ?? message.image() {
			return image.pngData()
		}
		return nil
	}

	// MARK: - Attachment Processing
	func processAttachment(_ attachment: Attachment, for message: Message) async throws -> Data {
		switch attachment.attachmentType {
		case .image:
			return try await processImageAttachment(attachment, for: message)

		case .imageUploading, .videoUploading:
			throw AttachmentError.invalidAttachmentState(attachment.attachmentType)

		case .video:
			return try await processVideoAttachment(attachment, for: message)

		case .link:
			return try await processLinkAttachment(attachment, for: message)
		}
	}

	// MARK: - Image Attachment
	func processImageAttachment(_ attachment: Attachment, for message: Message) async throws -> Data {
		let image = try await fetchImage(from: attachment.url)
		return try await saveImage(image, for: message)
	}

	// MARK: - Video Attachment
	func processVideoAttachment(_ attachment: Attachment, for message: Message) async throws -> Data {
		// TODO: Implement video thumbnail generation
		// For now, return empty data or implement basic video processing
		throw AttachmentError.invalidAttachmentState(.video)
	}

	// MARK: - Link Attachment
	func processLinkAttachment(_ attachment: Attachment, for message: Message) async throws -> Data {
		guard let url = URL(string: attachment.url) else {
			throw AttachmentError.invalidURL(attachment.url)
		}

		let linkData = try await LinkData.performFetch(for: url)
		guard let image = linkData.image else {
			throw AttachmentError.missingLinkImage
		}

		return try await saveImage(image, for: message)
	}

	// MARK: - Network Operations
	func fetchImage(from urlString: String) async throws -> UIImage {
		guard let url = URL(string: urlString) else {
			throw AttachmentError.invalidURL(urlString)
		}

		let (data, response) = try await urlSession.data(from: url)

		guard let httpResponse = response as? HTTPURLResponse,
			  (200...299).contains(httpResponse.statusCode) else {
			throw URLError(.badServerResponse)
		}

		guard let image = UIImage(data: data) else {
			throw AttachmentError.imageDecodingFailed
		}

		return image
	}

	// MARK: - File Operations
	func saveImage(_ uiImage: UIImage, for message: Message) async throws -> Data {
		do {
			let data = try mediaManager.createData(from: uiImage)
			let thumbnailData = try await mediaManager.createThumbnail(from: uiImage)

			try message.file()?.write(data)
			try message.thumbnailFile()?.write(thumbnailData)

			return thumbnailData
		} catch {
			throw AttachmentError.fileWriteFailed(error)
		}
	}
}
