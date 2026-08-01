//  MsgAttachmentsView.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database
import Services
import SwiftUI

struct MsgAttachmentsView: View {
    let state: MsgCellViewModel.State
    let isVisible: Bool

    @Namespace private var namespace
    @State private var selection: Attachment?
    @State private var uploadAccumulator = AttachmentUploadAccumulator()
    @Environment(\.msgCellActions) private var msgCellActions

    private var attachments: [Attachment] { state.attachments ?? [] }
    private var alignment: HorizontalAlignment { state.horizontalAlignment }

    var body: some View {
        AttachmentsDeck(items: attachments, alignment: alignment) { attachment in
            AttachmentPreview(attachment: attachment, isVisible: isVisible) { item in
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
        .onChange(of: state.msg.uid) {
            uploadAccumulator.reset()
        }
    }

    private func onUploaded(attachment: Attachment) {
        guard let completedAttachments = uploadAccumulator.complete(
            attachment,
            in: attachments
        ) else {
            return
        }

        var msg = state.msg
        msg.attachments = completedAttachments
        msgCellActions?(.onUploadedAttachments(msg))
    }
}
