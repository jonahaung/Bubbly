//
//  AttachmentDataAPI.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 20/10/25.
//

import Database
import LinkPresentation
import Services
import UIKit
import UniformTypeIdentifiers
import XUI

actor AttachmentDataAPI {
	enum AttachmentError: LocalizedError {
		case missingFileURL
		case missingImageID
		case invalidURL(String)
		case imageDecodingFailed
		case thumbnailCreationFailed
		case fileWriteFailed(Error)
		case invalidAttachmentState(AttachMentType)
		case missingLinkImage

		var errorDescription: String {
			switch self {
			case .missingImageID:
				"Message is missing image ID"
			case let .invalidURL(urlString):
				"Invalid URL: \(urlString)"
			case .imageDecodingFailed:
				"Failed to decode image data"
			case .thumbnailCreationFailed:
				"Failed to create thumbnail"
			case let .fileWriteFailed(error):
				"Failed to write file: \(error.localizedDescription)"
			case let .invalidAttachmentState(type):
				"Invalid attachment state: \(type)"
			case .missingLinkImage:
				"Link preview image is missing"
			case .missingFileURL:
				"File URL is missing"
			}
		}
	}

	private let mediaManager: MediaManager
	private let urlSession: URLSession
	private let swiftLinkPreview = SwiftLinkPreview()

	init(mediaManager: MediaManager = .shared, urlSession: URLSession = .shared) {
		self.mediaManager = mediaManager
		self.urlSession = urlSession
	}

	func fetchAttachmentData(for attachment: Attachment) async throws -> AttachmentData {
		if let cachedData = try  await cachedData(for: attachment) {
			return cachedData
		}
		return try await fetchDataAndCache(attachment)
	}
}

// MARK: - Private Implementation

private extension AttachmentDataAPI {
	// MARK: - Cached Image Handling

	func cachedData(for attachment: Attachment) async throws -> AttachmentData? {
		switch attachment.attachmentType {
		case .image:
			if attachment
				.fileExist(), let image = attachment
				.thumbnailImage() {
				return .image(thumbnail: image)
			}
			return nil
		case .link:
			if attachment
				.fileExist(), let image = attachment
				.image() {
				return .link(thumbnail: image)
			}
			return nil
		case .video:
			if attachment
				.fileExist(), let url = URL(string: attachment.url), let image = attachment
				.thumbnailImage() {
				return .video(videoURL: url, thumbnail: image)
			}
			return nil
		case .imageUploading:
			if attachment
				.fileExist(), let url = attachment.file()?.url, let image = attachment
				.thumbnailImage() {
				return .imageUpload(localURL: url, thumbnail: image)
			}
			return nil
		case .videoUploading:
			fatalError()
		}
	}

	// MARK: - Attachment Processing

	@concurrent
	func fetchDataAndCache(_ attachment: Attachment) async throws -> AttachmentData {
		switch attachment.attachmentType {
		case .image:
			return try await processImageAttachment(attachment)
		case .imageUploading, .videoUploading:
			throw AttachmentError.invalidAttachmentState(attachment.attachmentType)
		case .video:
			return try await processVideoAttachment(attachment)
		case .link:
			return try await processLinkAttachment(attachment)
		}
	}

	func processVideoAttachment(_ attachment: Attachment) async throws -> AttachmentData {
		guard let url = URL(string: attachment.url) else {
			throw AttachmentError.invalidURL(attachment.url)
		}
		let image = try await VideoFactory.generateVideoThumbnail(from: url)
		let thumbnail = try await saveImage(image, for: attachment)
		guard let url = attachment.localURL() else {
			throw AttachmentError.missingFileURL
		}
		return .video(videoURL: url, thumbnail: thumbnail)
	}
	// MARK: - Image Attachment

	func processImageAttachment(_ attachment: Attachment) async throws -> AttachmentData {
		let image = try await fetchImage(from: attachment.url)
		let thumbnail = try await saveImage(image, for: attachment)
		return .image(thumbnail: thumbnail)
	}

	func processLinkAttachment(_ attachment: Attachment) async throws -> AttachmentData {
		let image: UIImage
		if let thumbnailURLString = attachment.thumbnailUrl {
			image = try await fetchImage(from: thumbnailURLString)
		} else {
			let linkData = try await swiftLinkPreview.preview(attachment.url)
			let imageURL = linkData.imageURL

			if let imageURL {
				image = try await fetchImage(from: imageURL.absoluteString)
			} else {
				image = UIImage(systemSymbol: .photoOnRectangleAngled)
			}
		}
		try await saveImage(image, for: attachment)
		return .link(thumbnail: image)
	}

	func fetchImage(from urlString: String) async throws -> UIImage {
		guard let url = URL(string: urlString) else {
			throw AttachmentError.invalidURL(urlString)
		}
		let (data, response) = try await urlSession.data(from: url)
		guard let httpResponse = response as? HTTPURLResponse,
			  (200 ... 299).contains(httpResponse.statusCode)
		else {
			throw URLError(.badServerResponse)
		}
		guard let image = UIImage(data: data) else {
			throw AttachmentError.imageDecodingFailed
		}
		return image
	}

	// MARK: - File Operations

	@discardableResult
	func saveImage(_ uiImage: UIImage, for attachment: Attachment) async throws -> UIImage {
		let data = try mediaManager.createData(from: uiImage)
		let thumbnailData = try await mediaManager.createThumbnail(from: uiImage)
		guard let thumbnail = UIImage(data: thumbnailData) else {
			throw AttachmentError.imageDecodingFailed
		}
		if attachment.fileExist() == false {
			try attachment.file()?.write(data)
			try attachment.thumbnailFile()?.write(thumbnailData)
		} else {
			log("existed")
		}
		return thumbnail
	}
}
