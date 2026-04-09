// © 2026 Aung Ko Min

import Core
import Database
import ImagePlayground
import MediaPicker
import Services
import SwiftUI
import XUI

// MARK: - ChatComposer

@MainActor
@Observable
final class ChatComposer: ErrorPresenter {
    struct State: Hashable, Sendable, Equatable {
        var attachments: [Attachment] = []
        var menuIsOpened = false
        var source: ChatComposer.Source? = nil
    }

    var fileContent: String = ""
    @ObservationIgnored var inputText: InputText = .init()
    @ObservationIgnored var photoPicker: PhotoPickerManager = .init()
    @ObservationIgnored private let msgCreator: MsgCreator
    @ObservationIgnored private let worker: ChatComposerWorker = .init()

    var state: State = .init()

    init() {
        msgCreator = .init(currentUserId: currentUserID ?? "")
        inputText.delegate = self
        photoPicker.delegate = self
    }

    deinit {
        log("")
    }

    var hasContent: Bool {
        inputText.hasText || !state.attachments.isEmpty
    }

    func updateSource(_ source: ChatComposer.Source?) {
        if state.source == source {
            state.source = nil
            return
        }
        state.source = source
    }
}

extension ChatComposer {
    private func setLoading(_: Bool) {
//        isLoading = value
    }
}

// MARK: InputTextDelegate

extension ChatComposer: InputTextDelegate {
    func inputText(_: InputText, didInsertLinks links: [ExtractedLink]) {
        Task {
            await parseLinks(links: links)
        }
    }

    func inputText(_: InputText, didBeganEditing _: String) {
        if state.menuIsOpened {
            state.menuIsOpened = false
        }
    }
}

// MARK: PhotoPickerManagerDelegate

extension ChatComposer: PhotoPickerManagerDelegate {
    func photoPickerManager(
        _: PhotoPickerManager,
        didSelectImages images: [MediaPicker.SelectedImage],
    ) {
        Task {
            await parseImages(selectedImages: images)
        }
    }
}

extension ChatComposer {
    func handlePrimaryAction(_ conversation: Conversation) {
        let text = inputText.text
        if text.isWhitespace, state.attachments.isEmpty {
            inputText.set(text: Lorem.random())
            return
        }

        send(conversation: conversation)
    }

    func handleSecondaryAction(_ conversation: Conversation) {
        if hasContent {
            send(conversation: conversation)
        } else {
            resetSource()
        }
    }

    func resetSource() {
        state.source = nil
    }

    func send(conversation: Conversation) {
        let text = inputText.text.trimmed
        if text.isWhitespace {
            inputText.set(text: Lorem.random())
            return
        }
        Task {
            resetDraft()

            do {
                try await worker.sendMessage(
                    text: text,
                    attachments: state.attachments,
                    conversation: conversation,
                    msgCreator: msgCreator,
                )
            } catch {
                await showError(error)
            }
        }
    }

    func send(msg: ChatEngineMsgGenerable, conversation: Conversation) async throws {
        let msg = try await msgCreator.message(
            text: msg.content,
            attachments: [],
            in: conversation,
        )
        try await Socket.send(.newMsg(rMsg: .init(msg)), conversation: conversation)
    }

    func resetDraft() {
        inputText.clear()
        photoPicker.removeAll()
    }
}

extension ChatComposer {
    func parseLinks(links: [ExtractedLink]) async {
        var state = state
        let existingURLs = state.attachments.map(\.url)
        let newLinks = links.filter { existingURLs.contains($0.url.absoluteString) == false }
        guard newLinks.isEmpty == false else {
            return
        }

        setLoading(true)
        if let attachments = await worker.makeLinkAttachments(from: newLinks) {
            state.attachments.append(contentsOf: attachments)
            setLoading(false)
            self.state = state
        } else {
            setLoading(false)
        }
    }

    @concurrent
    func parseImages(selectedImages: [SelectedImage]) async {
        var state = await state
        await MainActor.run { self.setLoading(true) }
        await worker.processSelectedImages(
            selectedImages: selectedImages,
            attachments: &state.attachments,
        )
        await MainActor.run {
            self.setLoading(false)
            self.state = state
        }
    }

    @concurrent
    func generateImage(prompt: String) async throws {
        guard prompt.isWhitespace == false else {
            return
        }

        var state = await state
        await MainActor.run { self.setLoading(true) }
        if let attachment = try await worker.makeGeneratedImageAttachment(prompt: prompt) {
            state.attachments.append(attachment)
            await MainActor.run {
                self.inputText.clear()
                self.setLoading(false)
                self.state = state
            }
        } else {
            await MainActor.run { self.setLoading(false) }
        }
    }

    func removeAttachment(id: String) {
        var state = state
        photoPicker.remove(for: id)
        state.attachments.removeAll(where: { $0.id == id })
        self.state = state
    }
}

// MARK: - ChatComposerWorker

private actor ChatComposerWorker {
    func makeLinkAttachments(from links: [ExtractedLink]) async -> [Attachment]? {
        try? await AttachmentFactory.createLinkAttachments(from: links)
    }

    func makeImageAttachments(from images: [SelectedImage]) async -> [Attachment]? {
        try? await AttachmentFactory.createImageAttachments(from: images)
    }

    func makeGeneratedImageAttachment(prompt: String) async throws -> Attachment? {
        let imageCreator = try await ImageCreator()
        let createdImages = imageCreator.images(
            for: [.text(prompt)],
            style: .animation,
            limit: 1,
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
        msgCreator: MsgCreator,
    ) async throws {
        let sanitizedText = sanitizeText(text, attachments: attachments)
        let msg = try await msgCreator.message(
            text: sanitizedText,
            attachments: attachments,
            in: conversation,
        )
        if msg.attachments.contains(where: { $0.attachmentType == .imageUploading }) {
            await Socket.shared.notifyMessage(.newMsg(rMsg: .init(msg)))
        } else {
            try await Socket.send(.newMsg(rMsg: .init(msg)), conversation: conversation)
        }
    }

    private func sanitizeText(_ text: String, attachments: [Attachment]) -> String {
        guard attachments.isEmpty == false else {
            return text
        }

        var updated = text
        if updated == attachments.first?.url {
            return ""
        }
        for each in attachments {
            updated = updated.replace(each.url, with: "")
        }
        return updated.trimmed
    }

    func processSelectedImages(
        selectedImages: [SelectedImage],
        attachments: inout [Attachment],
    ) async {
        var items = attachments
        var pickerItems = selectedImages
        let pickerIDs = Set(pickerItems.map(\.id))
        items.removeAll { pickerIDs.contains($0.uid) == false }
        pickerItems.removeAll { item in items.contains { $0.uid == item.id } }

        if let newItems = await makeImageAttachments(from: pickerItems) {
            items.append(contentsOf: newItems)
        }

        attachments = items
    }
}
