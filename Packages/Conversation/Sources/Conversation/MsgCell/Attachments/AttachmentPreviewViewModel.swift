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
    public enum State: Hashable {
        case initial
        case attachMentData(AttachmentData)
        case error(String)
    }

    public var state = State.initial
    public var attachment: Attachment

    public init(attachment: Attachment) {
        self.attachment = attachment
    }

    public func cachedAttachmentData() -> AttachmentData? {
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
            await set(.attachMentData(cached))
        } else {
            do {
                let data = try await attachmentFetcher.fetch(
                    attachment,
                    intent: .visible
                )
                await set(.attachMentData(data))
            } catch {
                if error is CancellationError {
                    return
                }
                await set(.error(error.localizedDescription))
            }
        }
    }

    private func set(_ state: State) {
        self.state = state
    }
}
