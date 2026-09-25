//  MsgAttachmentsView.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database
import Services
import SwiftUI

struct MsgAttachmentsView: View {
    let state: MsgCellViewModel.State

    @Environment(\.sharedNamespace) private var namespace
    @State private var selection: Attachment?
    @Environment(\.msgCellActions) private var msgCellActions

    private var attachments: [Attachment] { state.attachments ?? [] }
    private var alignment: HorizontalAlignment { state.horizontalAlignment }

    var body: some View {
        if let namespace {
            AttachmentsDeck(items: attachments, alignment: alignment) { attachment in
                AttachmentPreview(attachment: attachment) { item in
                    selection = item
                } onCompleteUpload: {
                    onUploaded(attachment: $0)
                }
                .matchedTransitionSource(id: attachment.uid, in: namespace) { source in
                    source.background(.background)
                }
            }
            .fullScreenCover(item: $selection) { attachment in
                AttachmentGalleryView(attachments: attachments, selection: attachment.uid)
                    .navigationTransition(
                        .zoom(sourceID: attachment.uid, in: namespace)
                    )
            }
        }
    }

    private func onUploaded(attachment: Attachment) {
        guard var updatedAttachments = state.attachments,
            let index = updatedAttachments.firstIndex(where: { $0.uid == attachment.uid })
        else {
            return
        }

        updatedAttachments[index] = attachment
        var msg = state.msg
        msg.attachments = updatedAttachments
        msgCellActions?(.onUploadedAttachments(msg))
    }
}
