import Database

struct AttachmentUploadAccumulator {
    private var uploadedByID: [Attachment.ID: Attachment] = [:]
    private var completedBatchIDs: Set<Attachment.ID> = []

    mutating func complete(
        _ uploadedAttachment: Attachment,
        in attachments: [Attachment]
    ) -> [Attachment]? {
        let uploadingIDs = Set(
            attachments.lazy
                .filter { $0.attachmentType == .imageUploading }
                .map(\.id)
        )
        guard uploadingIDs.contains(uploadedAttachment.id) else {
            return nil
        }

        uploadedByID[uploadedAttachment.id] = uploadedAttachment
        guard uploadingIDs.isEmpty == false,
              uploadingIDs.isSubset(of: uploadedByID.keys),
              completedBatchIDs != uploadingIDs else {
            return nil
        }

        completedBatchIDs = uploadingIDs
        return attachments.map { uploadedByID[$0.id] ?? $0 }
    }

    mutating func reset() {
        uploadedByID.removeAll(keepingCapacity: true)
        completedBatchIDs.removeAll(keepingCapacity: true)
    }
}
