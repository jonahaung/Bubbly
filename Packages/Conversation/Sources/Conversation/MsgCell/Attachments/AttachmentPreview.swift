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

struct AttachmentPreview: View {

    let onSelect: (_ item: Attachment) -> Void
    let onCompleteUpload: ((_ newValue: Attachment) -> Void)?

    @Environment(\.attachmentFetcher) private var attachmentFetcher
    @Environment(\.conversation) private var conversation
    @Environment(MsgCellViewModel.self) private var viewModel
    @LazilyState private var model: AttachmentPreviewViewModel

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
                .onTapGesture {
                    onSelect(model.attachment)
                }
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
            .onTapGesture {
                onSelect(model.attachment)
            }
        }
    }

    private var content: some View {
        ZStack {
            Color.background
                .flexible(.all)
                .aspectRatio(model.attachment.aspectRatio, contentMode: .fit)
                .layoutPriority(1)
            switch model.state {
            case .initial:
                ProgressView()
                    .controlSize(.mini)
            case let .attachMentData(data):
                attachmentView(for: data)
            case let .error(error):
                SystemImage(.exclamationmarkTriangleFill)
                    .foregroundStyle(.red)
                    .presentSheet {
                        Text(error)
                            .padding()
                    }
            }
        }
        .equatable(by: model.state)
        .task(id: viewModel.isVisible) {
            guard let attachmentFetcher else {
                return
            }
            if viewModel.isVisible {
                await model.loadAttachment(attachmentFetcher: attachmentFetcher)
            } else {
                await attachmentFetcher.cancel(model.attachment)
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
                .if_let(onCompleteUpload) {
                    completion,
                    view in
                    view
                        .overlay {
                            ImageUploadingLayer(
                                attachment: model.attachment,
                                image: UIImage(
                                    contentsOfFile: url.absoluteString
                                )?.resized(toWidth: 1080) ?? thumbnail,
                                conversationID: conversation.uid
                            ) {
                                completion($0)
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
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            .transition(
                .asymmetric(
                    insertion: .opacity.animation(.default),
                    removal: .identity
                )
            )
            .accessibilityLabel("Open attachment")
    }
}
