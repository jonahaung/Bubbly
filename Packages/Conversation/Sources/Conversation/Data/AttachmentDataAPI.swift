// © 2026 Aung Ko Min

import Database
import Foundation
import Services
import UIKit
import XUI

actor AttachmentDataAPI {
    

    init(
        mediaManager: MediaManager = .shared,
        urlSession: URLSession = .shared,
        swiftLinkPreview: SwiftLinkPreview = SwiftLinkPreview(),
    ) {
        self.mediaManager = mediaManager
        self.urlSession = urlSession
        self.swiftLinkPreview = swiftLinkPreview
    }

    

    enum AttachmentError: LocalizedError {
        case missingFileURL
        case invalidURL(String)
        case invalidAttachmentState(AttachMentType)
        case imageDecodingFailed
        case badResponse(Int)

        

        var errorDescription: String? {
            switch self {
            case .missingFileURL:
                "File URL is missing"
            case let .invalidURL(urlString):
                "Invalid URL: \(urlString)"
            case let .invalidAttachmentState(type):
                "Invalid attachment state: \(type)"
            case .imageDecodingFailed:
                "Failed to decode image data"
            case let .badResponse(statusCode):
                "Invalid server response: \(statusCode)"
            }
        }
    }

    func fetchAttachmentData(for attachment: Attachment) async throws -> AttachmentData {
        switch attachment.attachmentType {
        case .image:
            if let cached = cachedImageThumbnail(for: attachment) {
                return cached
            }
            return try await processImageAttachment(attachment)
        case .imageUploading:
            if let cached = cachedUploadingImage(for: attachment) {
                return cached
            }
            throw AttachmentError.invalidAttachmentState(.imageUploading)
        case .video:
            if let cached = cachedVideo(for: attachment) {
                return cached
            }
            return try await processVideoAttachment(attachment)
        case .videoUploading:
            throw AttachmentError.invalidAttachmentState(.videoUploading)
        case .link:
            if let cached = cachedLink(for: attachment) {
                return cached
            }
            return try await processLinkAttachment(attachment)
        }
    }

    

    private let mediaManager: MediaManager
    private let urlSession: URLSession
    private let swiftLinkPreview: SwiftLinkPreview

    private func cachedImageThumbnail(for attachment: Attachment) -> AttachmentData? {
        guard attachment.fileExist(), let thumbnail = attachment.thumbnailImage() else {
            return nil
        }

        return .image(thumbnail: thumbnail)
    }

    private func cachedUploadingImage(for attachment: Attachment) -> AttachmentData? {
        guard
            attachment.fileExist(),
            let localURL = attachment.file()?.url,
            let thumbnail = attachment.thumbnailImage() else
        {
            return nil
        }

        return .imageUpload(localURL: localURL, thumbnail: thumbnail)
    }

    private func cachedVideo(for attachment: Attachment) -> AttachmentData? {
        guard let thumbnail = attachment.thumbnailImage() else {
            return nil
        }

        if attachment.fileExist(), let localURL = attachment.localURL() {
            return .video(videoURL: localURL, thumbnail: thumbnail)
        }

        guard let remoteURL = URL(string: attachment.url) else {
            return nil
        }

        return .video(videoURL: remoteURL, thumbnail: thumbnail)
    }

    private func cachedLink(for attachment: Attachment) -> AttachmentData? {
        guard attachment.fileExist(), let image = attachment.image() else {
            return nil
        }

        return .link(thumbnail: image)
    }

    private func processImageAttachment(_ attachment: Attachment) async throws -> AttachmentData {
        let image = try await fetchImage(from: attachment.url)
        let thumbnail = try await persistImageAndThumbnail(image, for: attachment)
        return .image(thumbnail: thumbnail)
    }

    private func processVideoAttachment(_ attachment: Attachment) async throws -> AttachmentData {
        guard let remoteURL = URL(string: attachment.url) else {
            throw AttachmentError.invalidURL(attachment.url)
        }

        let thumbnail = try await VideoFactory.generateVideoThumbnail(from: remoteURL)
        let persistedThumbnail = try await persistThumbnailOnly(thumbnail, for: attachment)
        if attachment.fileExist(), let localURL = attachment.localURL() {
            return .video(videoURL: localURL, thumbnail: persistedThumbnail)
        }
        return .video(videoURL: remoteURL, thumbnail: persistedThumbnail)
    }

    private func processLinkAttachment(_ attachment: Attachment) async throws -> AttachmentData {
        let image: UIImage
        if let thumbnailURLString = attachment.thumbnailURL {
            image = try await fetchImage(from: thumbnailURLString)
        } else {
            let linkData = try await swiftLinkPreview.preview(attachment.url)
            if let imageURL = linkData.imageURL {
                image = try await fetchImage(from: imageURL.absoluteString)
            } else {
                image = UIImage(systemSymbol: .photoOnRectangleAngled)
            }
        }
        try persistImageOnly(image, for: attachment)
        return .link(thumbnail: image)
    }

    private func fetchImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw AttachmentError.invalidURL(urlString)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        let (data, response) = try await urlSession.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200 ... 299).contains(http.statusCode) else {
            throw AttachmentError.badResponse(http.statusCode)
        }

        if let mimeType = http.mimeType, mimeType.hasPrefix("image/") == false {
            throw URLError(.cannotDecodeContentData)
        }

        guard let image = UIImage(data: data) else {
            throw AttachmentError.imageDecodingFailed
        }

        return image
    }

    @discardableResult
    private func persistImageAndThumbnail(
        _ image: UIImage,
        for attachment: Attachment,
    ) async throws -> UIImage {
        let originalData = try mediaManager.createData(from: image)
        let thumbnailData = try mediaManager.createThumbnail(from: image)
        guard let thumbnail = UIImage(data: thumbnailData) else {
            throw AttachmentError.imageDecodingFailed
        }

        try attachment.file()?.write(originalData)
        try attachment.thumbnailFile()?.write(thumbnailData)
        return thumbnail
    }

    private func persistImageOnly(_ image: UIImage, for attachment: Attachment) throws {
        let originalData = try mediaManager.createData(from: image)
        try attachment.file()?.write(originalData)
    }

    @discardableResult
    private func persistThumbnailOnly(
        _ image: UIImage,
        for attachment: Attachment,
    ) async throws -> UIImage {
        let thumbnailData = try mediaManager.createThumbnail(from: image)
        guard let thumbnail = UIImage(data: thumbnailData) else {
            throw AttachmentError.imageDecodingFailed
        }

        try attachment.thumbnailFile()?.write(thumbnailData)
        return thumbnail
    }
}
