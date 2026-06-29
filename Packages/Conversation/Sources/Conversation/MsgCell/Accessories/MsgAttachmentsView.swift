//  MsgAttachmentsView.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import WebKit
import SwiftUI

// © 2026 Aung Ko Min
import Database
import Services

struct MsgAttachmentsView: View {
    let state: MsgCellViewModel.State

    @Namespace private var namespace
    @State private var selection: Attachment?
    @Environment(\.msgCellActions) private var msgCellActions
    @Environment(\.conversation) private var conversation
    @State private var uploadedAttachments: [Attachment] = []

    private var attachments: [Attachment] { state.attachments ?? [] }
    private var alignment: HorizontalAlignment { state.horizontalAlignment }

    var body: some View {
        AttachmentsDeck(items: attachments, alignment: alignment ) { attachment in
            AttachmentPreview(attachment: attachment) { item in
                selection = item
            } onCompleteUpload: {
                onUploaded(attachment: $0)
            }
            .matchedTransitionSource(id: attachment.uid, in: namespace) { source in
                source.background(.clear)
            }
        }
        .fullScreenCover(item: $selection) { attachment in
            AttachmentGalleryView(attachments: attachments, selection: attachment.id)
                .navigationTransition(
                    .zoom(sourceID: attachment.uid, in: namespace)
                )
        }
    }

    private func onUploaded(attachment: Attachment) {
        uploadedAttachments.append(attachment)
        if attachments.count == uploadedAttachments.count {
            Task {
                let newValues = uploadedAttachments
                var msg = state.msg
                msg.attachments = newValues
                msgCellActions?(.onUploadedAttachments(msg))
            }
        }
    }
}
