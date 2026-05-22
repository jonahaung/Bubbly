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
    let onSelect: (_ item: Attachment) -> Void
    let onCompleteUpload: ((_ newValue: Attachment) -> Void)?

    @Environment(\.attachmentFetcher) private var attachmentFetcher
    @Environment(MsgCellViewModel.self) private var viewModel
    private var viewIsVisible: Bool { viewModel.isVisible }
    @Environment(\.conversation) private var conversation
    @LazyState private var model: AttachmentPreviewViewModel

    init(
        attachment: Attachment,
        onSelect: @escaping (_: Attachment) -> Void,
        onCompleteUpload: ((_ newValue: Attachment) -> Void)? = nil
    ) {
        _model = .init(wrappedValue: .init(attachment: attachment))
        self.onSelect = onSelect
        self.onCompleteUpload = onCompleteUpload
    }

    var body: some View {
        switch model.attachment.attachmentType {
        case .image,
             .imageUploading,
             .video,
             .videoUploading:
            content
        case .link:
            VStack(alignment: .center, spacing: 0) {
                content
                    .layoutPriority(1)
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
            if let data = model.attachmentData {
                attachmentView(for: data)
            } else if let error = model.error {
                Text(error.localizedDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(8)
            } else {
                RoundedRectangle(cornerRadius: Radius.md).fill(Color.background)
                ProgressView().controlSize(.mini)
            }
        }
        .aspectRatio(model.attachment.aspectRatio, contentMode: .fit)
        .animation(.smooth, value: model.attachmentData)
        .task(id: viewIsVisible) {
            if viewIsVisible, let attachmentFetcher {
                if model.attachmentData == nil {
                    if let cached = await model.cachedAttachmentData() {
                        model.attachmentData = cached
                    } else {
                        await model.loadAttachment(attachmentFetcher: attachmentFetcher)
                    }
                }
            } else {
                await attachmentFetcher?.cancel(model.attachment)
            }
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
