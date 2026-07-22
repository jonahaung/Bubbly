import Database
import ImagePlayground
import MediaPicker
import Services
import SwiftUI

actor ChatComposerWorker {
    func makeLinkAttachments(from links: [ExtractedLink]) async -> [Attachment] {
        (try? await AttachmentFactory.createLinkAttachments(from: links)) ?? []
    }

    func makeGeneratedImageAttachment(prompt: String) async throws -> Attachment? {
        let imageCreator = try await ImageCreator()
        let createdImages = imageCreator.images(
            for: [.text(prompt)],
            style: .animation,
            limit: 1
        )
        var image: UIImage?

        for try await created in createdImages {
            image = UIImage(cgImage: created.cgImage)
        }

        guard let image else {
            return nil
        }

        return try await AttachmentFactory.createImageAttachment(from: image)
    }

    func sendMessage(
        text: String,
        attachments: [Attachment],
        conversation: Conversation,
        msgCreator: MsgCreator
    ) async throws {
        let sanitizedText = sanitizeText(text, attachments: attachments)
        let message = try await msgCreator.message(
            text: sanitizedText,
            attachments: attachments,
            in: conversation
        )
        try await Socket.shared.send(.newMsg(rMsg: .init(message)))
    }

    func processSelectedImages(
        selectedImages: [SelectedImage],
        attachments: [Attachment]
    ) async -> [Attachment] {
        let selectedIDs = Set(selectedImages.map(\.id))
        var nextAttachments = attachments.filter { selectedIDs.contains($0.uid) }
        let existingIDs = Set(nextAttachments.map(\.uid))
        let newImages = selectedImages.filter { !existingIDs.contains($0.id) }

        if let newAttachments = try? await AttachmentFactory.createImageAttachments(from: newImages) {
            nextAttachments.append(contentsOf: newAttachments)
        }

        return nextAttachments
    }

    private func sanitizeText(_ text: String, attachments: [Attachment]) -> String? {
        var sanitizedText = text
        for attachment in attachments {
            sanitizedText = sanitizedText.replace(attachment.url, with: "")
        }
        sanitizedText = sanitizedText.trimmed
        return sanitizedText.isWhitespace ? nil : sanitizedText
    }
}
