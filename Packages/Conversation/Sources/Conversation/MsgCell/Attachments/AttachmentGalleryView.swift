#if os(iOS)
//
//  AttachmentGalleryView.swift
//  Conversation
//
//  Created by Aung Ko Min on 21/3/26.
//


import Database
import SwiftUI
import XUI

public struct AttachmentGalleryView: View {
    private let attachments: [Attachment]
    @State private var selection: String
    @Environment(\.dismiss) private var dismiss
    @State private var showControls = false

    public init(attachments: [Attachment], selection: String) {
        self.attachments = attachments
        self.selection = selection
    }

    public var body: some View {
        PagerScrollView(items: attachments, selection: $selection) { item in
            AttachmentGalleryCell(attachment: item)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            topBar
                .opacity(showControls ? 1 : 0)
        }
        .if(attachments.count > 1) { view in
            view
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomBar
                        .opacity(showControls ? 1 : 0)
                }
        }
        .background(.bar, ignoresSafeAreaEdges: .all)
        .statusBarHidden()
        .animation(.default, value: showControls)
        .onAppear(after: 1) {
            showControls = true
        }
    }

    private var topBar: some View {
        HStack {
            DismissButton(dismiss: dismiss)
            Spacer()
            shareButton
        }
        .padding()
        .buttonStyle(.borderless)
    }

    private var bottomBar: some View {
        XPhotoPageControl(selection: $selection, items: attachments.map(\.id), size: 20)
            .padding()
    }

    @ViewBuilder private var shareButton: some View {
        let currentItem = attachments.first(where: { $0.id == selection })
        if
            let item = currentItem,
            item.attachmentType == .image,
            let url = item.galleryURL,
            let data = try? Data(contentsOf: url),
            let uIImage = UIImage(data: data) {
            let image = Image(uiImage: uIImage)
            ShareLink(
                item: image,
                preview: SharePreview(item.galleryTitle ?? "", image: image)
            )
            .labelStyle(.iconOnly)
        }
    }
}

#endif
