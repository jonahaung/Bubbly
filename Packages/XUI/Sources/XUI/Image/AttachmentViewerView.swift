//
//  AttachmentViewerView.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 27/7/23.
//

import ImageLoader
import SwiftUI

public struct AttachmentViewerView: View {
    @State private var attachment: XAttachment

    public init(
        _ attachment: XAttachment
    ) {
        self.attachment = attachment
    }

    @ViewBuilder
    public var body: some View {
        switch attachment.type {
        case .photo:
            ZStack {
                Rectangle().fill(.thickMaterial)
                    .ignoresSafeArea(.container, edges: .all)
                content
            }
            .safeAreaInset(edge: .top) {
                toolBar
            }
        case .video:
            if let url = attachment.url {
                MediaPlayerView(url: url)
            }
        }
    }

    private var content: some View {
        LazyImage(url: attachment.url) { state in
            switch state.result {
            case let .success(image):
                Image(uiImage: image.image)
                    .resizable()
                    .scaledToFit()
                    .onAppear {
                        if attachment.initialImageData == nil {
                            attachment.initialImageData = state.imageContainer?.data
                        }
                    }
            case let .failure(error):
                Text(error.localizedDescription)
            case .none:
                if let data = attachment.initialImageData, let fileImage = UIImage(
                    data: data) {
                    Image(uiImage: fileImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    ProgressView().controlSize(.mini)
                }
            }
        }
        .zoomable()
    }

    private var toolBar: some View {
        HStack(alignment: .bottom) {
            Spacer()
            shareButton
        }
        .padding()
    }

    @ViewBuilder private var shareButton: some View {
        if let data = attachment.initialImageData, let fileImage = UIImage(
            data: data
        ) {
            ShareLink(
                item: Image(uiImage: fileImage),
                preview: SharePreview(attachment.urlString, icon: Image(uiImage: fileImage))
            )
            .labelStyle(.iconOnly)
        } else if let url = attachment.url {
            ShareLink(item: url, preview: SharePreview(attachment.urlString))
                .labelStyle(.iconOnly)
        }
    }
}

public struct PhotoViewer: View {
    private let attachment: XAttachment
    private let title: String
    @Environment(\.dismiss) private var dismiss

    public init(_ attachment: XAttachment, title: String = "") {
        self.attachment = attachment
        self.title = title
    }

    public var body: some View {
        AttachmentViewerView(attachment)
            .colorScheme(.dark)
            .tint(.white)
    }
}
