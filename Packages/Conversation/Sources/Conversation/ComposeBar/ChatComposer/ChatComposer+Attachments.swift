import Database
import MediaPicker

extension ChatComposer {
    func parseLinks(links: [ExtractedLink]) async {
        let currentURLs = Set(links.map { $0.url.absoluteString })
        state.attachments.removeAll {
            $0.attachMentTypeRaw == AttachMentType.link.rawValue && !currentURLs.contains($0.url)
        }

        let existingURLs = Set(
            state.attachments
                .filter { $0.attachMentTypeRaw == AttachMentType.link.rawValue }
                .map(\.url)
        )
        let newLinks = links.filter { !existingURLs.contains($0.url.absoluteString) }
        guard !newLinks.isEmpty else {
            return
        }

        setProcessing(true)
        let attachments = await worker.makeLinkAttachments(from: newLinks)
        state.attachments.append(contentsOf: attachments)
        setProcessing(false)
    }

    func parseImages(selectedImages: [SelectedImage]) async {
        setProcessing(true)
        state.attachments = await worker.processSelectedImages(
            selectedImages: selectedImages,
            attachments: state.attachments
        )
        setProcessing(false)
    }

    func generateImage(prompt: String) async throws {
        guard !prompt.isWhitespace else {
            return
        }

        setProcessing(true)
        defer {
            setProcessing(false)
        }

        guard let attachment = try await worker.makeGeneratedImageAttachment(prompt: prompt) else {
            return
        }

        state.attachments.append(attachment)
        inputText.clear()
    }

    func removeAttachment(id: String) {
        photoPicker.remove(for: id)
        state.attachments.removeAll { $0.uid == id }
    }
}
