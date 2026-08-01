//  AttachmentPreviewViewModel.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database
import Services
import Foundation

@MainActor
@Observable
public final class AttachmentPreviewViewModel {
    public var attachment: Attachment
    public var attachmentData: AttachmentData?
    public var error: Error?

    public init(attachment: Attachment) {
        self.attachment = attachment
    }

    @concurrent
    public func cachedAttachmentData() async -> AttachmentData? {
        let attachment = await attachment
        switch attachment.attachmentType {
        case .image:
            if attachment.fileExist(),
               let thumb = attachment.thumbnailImage()
            {
                return .image(thumbnail: thumb)
            }
        case .imageUploading:
            if attachment.fileExist(),
               let url = attachment.file()?.url,
               let thumb = attachment.thumbnailImage()
            {
                return .imageUpload(localURL: url, thumbnail: thumb)
            }
        case .video:
            if attachment.fileExist(),
               let url = attachment.localURL(),
               let thumb = attachment.thumbnailImage()
            {
                return .video(videoURL: url, thumbnail: thumb)
            }
        case .link:
            if attachment.fileExist(),
               let thumb = attachment.image()
            {
                return .link(thumbnail: thumb)
            }
        case .videoUploading:
            break
        }
        return nil
    }

    @concurrent
    public func loadAttachment(attachmentFetcher: AttachmentFetcher) async {
        async let cached = cachedAttachmentData()
        if let cached = await cached {
            Task { @MainActor in
                attachmentData = cached
            }
        } else {
            do {
                let data = try await attachmentFetcher.fetch(
                    attachment,
                    intent: .prefetch
                )
                await MainActor.run {
                    attachmentData = data
                    error = nil
                }
            } catch {
                await MainActor.run {
                    if error is CancellationError {
                        return
                    }
                    self.error = error
                }
            }
        }
    }
}
