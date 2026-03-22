//
//  AttachmentPreview.swift
//  Conversation
//
//  Created by Aung Ko Min on 21/3/26.
//


import Database
import ImageLoader
import QuickLook
import Services
import SwiftUI
import VideoLoader
import XUI

struct AttachmentPreview: View {
    let onSelect: (_ item: Attachment) -> Void
    let onCompleteUpload: ((_ newValue: Attachment) -> Void)?

    @Environment(\.attachmentFetcher) private var attachmentFetcher
    @Environment(\.isVisible) private var viewIsVisible
    @Environment(\.conversation) private var conversation
    @Environment(\.msgCellActions) private var sendMsgCellInteraction
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
        case .image, .imageUploading, .video, .videoUploading:
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
            .allowsTightening(true)
            .background()
        }
    }

    private var content: some View {
        ZStack {
            Rectangle().fill(.fill.quinary)
            if let data = model.attachmentData {
                attachmentView(for: data)
            } else if let error = model.error {
                Text(error.localizedDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(8)
            } else {
                ProgressView().controlSize(.mini)
            }
        }
        .aspectRatio(model.attachment.aspectRatio, contentMode: .fit)
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
            .onTapGesture {
                onSelect(model.attachment)
            }
    }
}
