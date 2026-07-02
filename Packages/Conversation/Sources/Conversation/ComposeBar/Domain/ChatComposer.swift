//  ChatComposer.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database
import Services
import MediaPicker
import ImagePlayground

@MainActor
@Observable
final class ChatComposer: ErrorPresenter {
    struct State: Hashable, Sendable, Equatable {
        var attachments: [Attachment] = []
        var menuIsOpened = false
        var source: ChatComposer.Source?
        var isProcessing = false
    }

    var fileContent: String = ""
    @ObservationIgnored var inputText: InputText = .init()
    @ObservationIgnored var photoPicker: PhotoPickerManager = .init()
    @ObservationIgnored private let msgCreator: MsgCreator
    @ObservationIgnored private let worker: ChatComposerWorker = .init()
    @ObservationIgnored private let queue = AsyncQueue()

    var state: State = .init()

    init() {
        msgCreator = .init()
        inputText.delegate = self
        photoPicker.delegate = self
    }

    var hasContent: Bool {
        inputText.hasText || !state.attachments.isEmpty
    }

    var canSend: Bool {
        hasContent && state.isProcessing == false
    }

    func updateSource(_ source: ChatComposer.Source?) {
        if state.source == source {
            state.source = nil
            return
        }
        state.source = source
        if source?.keepsMenuOpen == false {
            state.menuIsOpened = false
        }
    }
}

extension ChatComposer {
    private func setLoading(_ value: Bool) {
        state.isProcessing = value
    }
}


extension ChatComposer: InputTextDelegate {
    func inputText(_: InputText, didInsertLinks links: [ExtractedLink]) {
        queue.addOperation { [weak self] in
            guard let self else { return }
            await parseLinks(links: links)
        }
    }

    func inputText(_: InputText, didBeganEditing _: String) {
        if state.menuIsOpened {
            state.menuIsOpened = false
        }
    }
    func inputText(_ inputText: InputText, didEndEditing text: String) {
        state.attachments = []
    }
    func inputText(_ inputText: InputText, didInsert text: String) {
        print(text)
    }
    
}

// MARK: PhotoPickerManagerDelegate

extension ChatComposer: PhotoPickerManagerDelegate {
    func photoPickerManager(
        _: PhotoPickerManager,
        didSelectImages images: [MediaPicker.SelectedImage]
    ) {
        
        queue.addOperation { [weak self] in
            guard let self else { return }
            await parseImages(selectedImages: images)
        }
    }
}

extension ChatComposer {
    func handlePrimaryAction(_ conversation: Conversation) {
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
        let text = inputText.text.string.trimmed
        let attachments = state.attachments
        
        queue.addOperation { [weak self] in
            guard let self else { return }
            resetDraft()
            try await worker.sendMessage(
                text: text,
                attachments: attachments,
                conversation: conversation,
                msgCreator: msgCreator
            )
        }
        
    }

    func resetDraft() {
        inputText.clear()
        photoPicker.removeAll()
        state.attachments.removeAll()
        state.source = nil
        state.isProcessing = false
    }
}

extension ChatComposer {
    func parseLinks(links: [ExtractedLink]) async {
        var nextState = state
        let currentURLs = Set(links.map { $0.url.absoluteString })

        nextState.attachments.removeAll { attachment in
            attachment.attachMentTypeRaw == AttachMentType.link.rawValue && currentURLs.contains(attachment.url) == false
        }

        let existingURLs = Set(
            nextState.attachments
                .filter { $0.attachMentTypeRaw == AttachMentType.link.rawValue }
                .map(\.url)
        )
        let newLinks = links.filter { existingURLs.contains($0.url.absoluteString) == false }
        guard newLinks.isEmpty == false else {
            state = nextState
            return
        }

        setLoading(true)
        if let attachments = await worker.makeLinkAttachments(from: newLinks) {
            nextState.attachments.append(contentsOf: attachments)
        }
        nextState.isProcessing = false
        state = nextState
    }

    func parseImages(selectedImages: [SelectedImage]) async {
        var state = state
        setLoading(true)
        await worker.processSelectedImages(
            selectedImages: selectedImages,
            attachments: &state.attachments
        )
        setLoading(false)
        self.state = state
    }

    func generateImage(prompt: String) async throws {
        guard prompt.isWhitespace == false else {
            return
        }

        var state = state
        setLoading(true)
        if let attachment = try await worker.makeGeneratedImageAttachment(prompt: prompt) {
            state.attachments.append(attachment)
            inputText.clear()
            setLoading(false)
            self.state = state
        } else {
            setLoading(false)
        }
    }

    func removeAttachment(id: String) {
        var state = state
        photoPicker.remove(for: id)
        state.attachments.removeAll(where: { $0.uid == id })
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
        let msg = try await msgCreator.message(
            text: sanitizedText,
            attachments: attachments,
            in: conversation
        )
        try await Socket.shared.send(.newMsg(rMsg: .init(msg)))
    }

    private func sanitizeText(_ text: String, attachments: [Attachment]) -> String? {
        var text = text
        attachments.forEach { each in
            text = text.replace(each.url, with: "")
        }
        text = text.trimmed
        if text.isWhitespace {
            return nil
        }
        return text
    }

    func processSelectedImages(
        selectedImages: [SelectedImage],
        attachments: inout [Attachment]
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
