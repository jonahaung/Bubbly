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
                            .font(Typography.system.footnote)
                            .bold()
                        if let description = model.attachment.subTitle {
                            Text(description)
                                .font(Typography.system.caption2)
                                .foregroundStyle(Color.secondaryText)
                        }
                    }
                    .lineHeight(.multiple(factor: 1.2))
                    .lineSpacing(0)
                    .multilineTextAlignment(.leading)
                    .padding(8)
                }
            }
            .background(Color.background)
        }
    }

    private var content: some View {
        ZStack {
            if isVisible {
                if let data = model.attachmentData {
                    attachmentView(for: data)
                } else if let error = model.error {
                    SystemImage(.exclamationmarkTriangleFill)
                        .foregroundStyle(.red)
                        .presentSheet {
                            Text(error.localizedDescription)
                                .padding()
                        }
                } else {
                    Color.background
                    ProgressView()
                        .controlSize(.mini)
                }
            } else {
                Color.background
            }
        }
        .aspectRatio(model.attachment.aspectRatio, contentMode: .fit)
        .task {
            guard let attachmentFetcher else {
                return
            }
            await model.loadAttachment(attachmentFetcher: attachmentFetcher)
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
        Button {
            onSelect(model.attachment)
        } label: {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .clipShape(.rect(cornerRadius: Radius.card))
        }
        .accessibilityLabel("Open attachment")
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
    }
}
