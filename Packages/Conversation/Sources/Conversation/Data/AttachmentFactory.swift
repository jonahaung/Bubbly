//  AttachmentFactory.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import UIKit
import Database
import Services
import MediaPicker
import AVFoundation

// MARK: - AttachmentFactory

public struct AttachmentFactory {
    public init() {}
}

extension AttachmentFactory {
    static func createImageAttachments(from items: [SelectedImage]) async throws -> [Attachment] {
        try await AsyncOrderedStream.mapOrdered(inputs: items) { item in
            try await createImageAttachment(from: item)
        }
    }

    static func createImageAttachment(from item: SelectedImage) throws -> Attachment {
        let image = item.image
        let imageData = try MediaManager.shared.createData(from: image)
        let thumbnailData = try MediaManager.shared.createThumbnail(from: image)

        var attachment = Attachment(
            uid: item.id,
            url: "",
            attachMentTypeRaw: AttachMentType.imageUploading.rawValue,
            aspectRatio: image.aspectRatio
        )
        guard let url = attachment.file()?.url else {
            throw CocoaError(.fileReadUnknown)
        }

        attachment.url = url.absoluteString
        try attachment.file()?.write(imageData)
        try attachment.thumbnailFile()?.write(thumbnailData)
        return attachment
    }

    static func createImageAttachment(from uiImages: [UIImage]) async throws -> [Attachment] {
        try await AsyncOrderedStream.mapOrdered(inputs: uiImages) { item in
            try await createImageAttachment(from: item)
        }
    }

    static func createImageAttachment(from uiImage: UIImage) async throws -> Attachment {
        let imageData = try MediaManager.shared.createData(from: uiImage)
        let thumbnailData = try MediaManager.shared.createThumbnail(from: uiImage)

        var attachment = await Attachment(
            uid: IDGenerator.shared.make(),
            url: "",
            attachMentTypeRaw: AttachMentType.imageUploading.rawValue,
            aspectRatio: uiImage.aspectRatio
        )
        guard let url = attachment.file()?.url else {
            throw CocoaError(.fileReadUnknown)
        }

        try attachment.file()?.write(imageData)
        try attachment.thumbnailFile()?.write(thumbnailData)
        attachment.url = url.absoluteString
        return attachment
    }
}

extension AttachmentFactory {
    static func createLinkAttachments(from items: [ExtractedLink]) async throws -> [Attachment] {
        try await AsyncOrderedStream.mapOrdered(inputs: items) { item in
            await createLinkAttachment(from: item.url)
        }.compactMap(\.self)
    }

    static func createLinkAttachment(from url: URL) async -> Attachment? {
        if await isVideoURLByContentType(url) {
            return await makeVideoAttachment(from: url.absoluteString)
        }
        let swiftLinkPreview = SwiftLinkPreview()
        let extracted: SwiftLinkPreviewResponse? = try? await swiftLinkPreview.preview(
            url.absoluteString
        )
        guard let extracted else {
            return nil
        }

        guard let imageURL = extracted.imageURL,
              let image = try? await getImage(from: imageURL) else {
            return nil
        }

        return await Attachment(
            uid: IDGenerator.shared.make(),
            url: url.absoluteString,
            thumbnailUrl: imageURL.absoluteString,
            attachMentTypeRaw: AttachMentType.link.rawValue,
            aspectRatio: image.aspectRatio,
            title: extracted.title,
            subTitle: extracted.description
        )
    }

    static func isYouTubeURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else {
            return false
        }

        return host.contains("youtube.com")
            || host.contains("youtu.be")
            || host.contains("youtube-nocookie.com")
    }

    static func isVideoURLByContentType(_ url: URL) async -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  let contentType = http.value(forHTTPHeaderField: "Content-Type") else {
                return false
            }

            return contentType.starts(with: "video/")
        } catch {
            return false
        }
    }
}

extension AttachmentFactory {
    static func makeVideoAttachment(from text: String) async -> Attachment? {
        guard let url = URL(string: text),
              let thumbnail = try? await VideoFactory.generateVideoThumbnail(from: url) else {
            return nil
        }

        return await Attachment(
            uid: IDGenerator.shared.make(),
            url: text,
            attachMentTypeRaw: AttachMentType.video.rawValue,
            aspectRatio: thumbnail.aspectRatio,
            title: ""
        )
    }

    static func getImage(from url: URL) async throws -> UIImage? {
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200 ... 299).contains(http.statusCode) {
            return nil
        }
        if let mime = (response as? HTTPURLResponse)?.mimeType,
           !mime.lowercased().hasPrefix("image/") {}
        return UIImage(data: data)
    }
}
