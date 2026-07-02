//  AttachmentGalleryCell.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import WebKit
import SwiftUI
import Database
import ImageLoader

public struct AttachmentGalleryCell: View {
    let attachment: Attachment
    @Environment(\.openURL) private var openURL

    public var body: some View {
        switch attachment.attachmentType {
        case .image,
             .imageUploading:
            imageContent
        case .link:
            VStack(spacing: 8) {
                previewContent(isZoomEnabled: false)
                if let title = attachment.title {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.headline)
                        if let subTitle = attachment.subTitle {
                            Text(subTitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineHeight(.leading(increase: 2))
                        }

                        if let url = URL(string: attachment.url) {
                            Link(destination: url) {
                                Label(
                                    url.host() ?? url.absoluteString,
                                    systemImage: "globe.fill"
                                )
                            }
                        }
                    }
                    .flexible(.horizontal)
                    .multilineTextAlignment(.leading)
                }
                Spacer()
                Button {
                    if let url = URL(string: attachment.url) {
                        openURL(url)
                    }
                } label: {
                    Text("Open in Safari")
                        .flexible(.horizontal)
                }
                .buttonStyle(.roundedButtonStyle)
                .padding(.horizontal)
            }.padding()
        case .video,
             .videoUploading:
            VideoAttachmentView(attachment: attachment)
        }
    }

    @ViewBuilder
    private var imageContent: some View {
        previewContent(isZoomEnabled: true)
    }

    @ViewBuilder
    private func previewContent(isZoomEnabled: Bool) -> some View {
        LazyImage(url: attachment.galleryURL, transaction: .withAnimation()) { state in
            switch state.result {
            case let .success(success):
                let image = Image(uiImage: success.image)
                    .resizable()
                    .scaledToFit()
                if isZoomEnabled {
                    image.zoomable()
                } else {
                    image
                }
            case let .failure(failure):
                ContentUnavailableView {
                    Text("Error")
                } description: {
                    Text(failure.localizedDescription)
                }
            case .none:
                ProgressView().controlSize(.mini)
            }
        }
    }
}
