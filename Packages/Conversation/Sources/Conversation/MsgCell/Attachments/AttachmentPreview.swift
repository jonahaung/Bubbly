//  AttachmentPreview.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database
import Services
import QuickLook
import ImageLoader
import VideoLoader

struct AttachmentPreview: View {
    let isVisible: Bool
    let onSelect: (_ item: Attachment) -> Void
    let onCompleteUpload: ((_ newValue: Attachment) -> Void)?

    @Environment(\.attachmentFetcher) private var attachmentFetcher
    @Environment(\.conversation) private var conversation
    @LazyState private var model: AttachmentPreviewViewModel

    init(
        attachment: Attachment,
        isVisible: Bool = true,
        onSelect: @escaping (_: Attachment) -> Void,
        onCompleteUpload: ((_ newValue: Attachment) -> Void)? = nil
    ) {
        _model = .init(wrappedValue: .init(attachment: attachment))
        self.isVisible = isVisible
        self.onSelect = onSelect
        self.onCompleteUpload = onCompleteUpload
    }

    var body: some View {
        switch model.attachment.attachmentType {
        case .image, .imageUploading, .video, .videoUploading:
            content
        case .link:
            VStack(alignment: .center, spacing: 0) {
                content
                if let title = model.attachment.title, title.isWhitespace == false {
                    VStack(alignment: .center, spacing: 4) {
                        Text(title)
                            .font(.system(size: 12, weight: .semibold))
                        if let description = model.attachment.subTitle {
                            Text(description)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .lineHeight(.multiple(factor: 1.2))
                    .lineSpacing(0)
                    .multilineTextAlignment(.leading)
                    .padding(8)
                    .flexible(.horizontal)
                }
            }
        }
    }

    private var content: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.background)
            if let data = model.attachmentData {
                AttachmentDataView(data: data) {
                    onSelect(model.attachment)
                }
            } else if let error = model.error {
                SystemImage(.exclamationmarkTriangleFill)
                    .foregroundColor(.red)
                    .presentSheet {
                        Text(error.localizedDescription)
                            .padding()
                    }
            } else {
                ProgressView()
                    .controlSize(.mini)
            }
        }
        .aspectRatio(model.attachment.aspectRatio, contentMode: .fit)
        .task(id: isVisible) {
            guard let attachmentFetcher else {
                return
            }
            if isVisible {
                if model.attachmentData == nil {
                    if let cached = await model.cachedAttachmentData() {
                        model.attachmentData = cached
                    } else {
                        await model.loadAttachment(attachmentFetcher: attachmentFetcher)
                    }
                }
            } else {
                await attachmentFetcher.cancel(model.attachment)
                model.attachmentData = nil
                model.error = nil
            }
        }
        .onDisappear {
            guard let attachmentFetcher else {
                return
            }
            Task {
                await attachmentFetcher.cancel(model.attachment)
            }
            model.attachmentData = nil
            model.error = nil
        }
    }

    @ViewBuilder
    private func attachmentView(for data: AttachmentData) -> some View {
        switch data {
        case let .image(thumbnail):
            imageView(for: thumbnail)
        case let .link(thumbnail):
            imageView(for: thumbnail)
        case let .imageUpload(url, thumbnail):
            imageView(for: thumbnail)
                .if_let(onCompleteUpload) { _, view in
                    view
                        .overlay {
                            ImageUploadingLayer(
                                attachment: model.attachment, url: url,
                                conversationID: conversation.uid
                            ) {
                                onCompleteUpload?($0)
                            }
                        }
                }
        case .video(videoURL: _, thumbnail: let thumbnail):
            imageView(for: thumbnail)
                .overlay {
                    SystemImage(.playFill, 22)
                        .foregroundStyle(Color.white)
                }
        }
    }

    private func imageView(for uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
            .onTapGesture {
                onSelect(model.attachment)
            }
    }
}
