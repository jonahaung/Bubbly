//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Services
import SwiftUI
import WebKit
import XUI

struct MsgAttachmentsView: View {
    let attachments: [Attachment]
    let alignment: HorizontalAlignment
    @Namespace private var namespace
    @State private var selection: Attachment?
    @Environment(MsgCellViewModel.self) private var viewModel
    @Environment(\.msgCellActions) private var msgCellActions
    @Environment(\.conversation) private var conversation
    @State private var uploadedAttachments = [Attachment]()

    var body: some View {
        AttachmentsDeck(
            items: attachments,
            alignment: alignment
        ) { attachment in
            AttachmentPreview(attachment: attachment) { item in
                selection = item
            } onCompleteUpload: {
                onUploaded(attachment: $0)
            }
            .matchedTransitionSource(id: attachment.uid, in: namespace) { source in
                source
                    .background(.clear)
            }
        }
        .fullScreenCover(item: $selection) { attachment in
            AttachmentGalleryView(attachments: attachments, selection: attachment.id)
                .presentationContentInteraction(.scrolls)
                .presentationBackgroundInteraction(.disabled)
                .presentationBackground(.clear)
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
                var msg = viewModel.msg
                msg.attachments = newValues
                msgCellActions?(.onUploadedAttachments(msg))
            }
        }
    }
}
