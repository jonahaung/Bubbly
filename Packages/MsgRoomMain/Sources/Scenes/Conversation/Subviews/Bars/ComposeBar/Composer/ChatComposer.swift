//
//  ChatComposer.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 26/6/24.
//

import Core
import Database
import MediaPicker
import Services
import SwiftUI
import XUI
import ImagePlayground

@MainActor
@Observable
final class ChatComposer: ErrorPresenter, Equatable {

	@ObservationIgnored var inputText = InputText()
	@ObservationIgnored var photoPicker = PhotoPickerManager()
	@ObservationIgnored private let msgCreator: MsgCreator
	@ObservationIgnored private let id: String

	let chantEngine = ChatEngine()
	var lastTopic: TopicGenerable?
	var attachments: [Attachment] = []
	var source: ChatComposer.Source = .text
	var isLoading = false

	init(id: String) {
		self.id = id
		msgCreator = .init(currentUserId: currentUserId ?? "")
		inputText.delegate = self
		photoPicker.delegate = self
	}
	deinit {
		log("")
	}
	
	var hasContent: Bool {
		inputText.hasText || !attachments.isEmpty
	}

	func updateSource(_ newValue: ChatComposer.Source) {
		source = newValue
	}
	nonisolated static func == (lhs: ChatComposer, rhs: ChatComposer) -> Bool {
		lhs.id == rhs.id
	}
}

private extension ChatComposer {
	func setLoading(_ value: Bool) {
		isLoading = value
	}
}

extension ChatComposer: InputTextDelegate {
	func inputText(_ inputText: InputText, didInsertLinks links: [ExtractedLink]) {
		Task {
			await parseLinks(links: links)
		}
	}

	func inputText(_ inputText: InputText, didBeganEditing text: String) {
		if text.isEmpty {
			attachments.removeAll()
		} else {
			source = .text
		}
	}
}

extension ChatComposer: PhotoPickerManagerDelegate {
	func photoPickerManager(
		_ manager: PhotoPickerManager,
		didSelectImages images: [MediaPicker.SelectedImage]
	) {
		Task {
			await parseImages(selectedImages: images)
		}
	}

}
extension ChatComposer {
	// MARK: - User Actions
	func handlePrimaryAction(_ conversation: Conversation) {
		let text = inputText.text
		if text.isWhitespace && attachments.isEmpty {
			inputText.text = Lorem.random()
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
		source = .text
	}
	func send(conversation: Conversation) {
		let text = inputText.text.trimmed
		let attachments = self.attachments
		resetDraft()
		Task {
			do {
				try await send(text: text, attachments: attachments, conversation: conversation)
			} catch {
				await self.showError(error)
			}
		}
	}

	func send(msg: ChatEngineMsgGenerable, conversation: Conversation) async throws {
		let msg = try await msgCreator.message(
			text: msg.content,
			attachments: [],
			in: conversation
		)
		try await Socket.shared.send(.newMsg(rMsg: .init(msg)), conversation: conversation)
	}
	@concurrent func send(text: String, attachments: [Attachment], conversation: Conversation) async throws {
		var msg = try await msgCreator.message(
			text: text,
			attachments: attachments,
			in: conversation
		)
		if attachments.isEmpty == false, var text = msg.text {
			if text == attachments.first?.url {
				msg.text = nil
			} else {
				attachments.forEach { each in
					text = text.replace(each.url, with: "")
				}
				msg.text = text.trimmed
			}
		}

		if msg.attachments.contains(where: { $0.attachmentType == .imageUploading }) {
			await Socket.shared.notifyMessage(.newMsg(rMsg: .init(msg)))
		} else {
			try await Socket.shared.send(.newMsg(rMsg: .init(msg)), conversation: conversation)
		}
	}

	func resetDraft() {
		inputText.clear()
		attachments.removeAll()
		photoPicker.removeAll()
		source = .text
	}
}

extension ChatComposer {
	// MARK: - Async Processing
	@concurrent
	func parseLinks(links: [ExtractedLink]) async {
		let items = await self.attachments
		let existingURLs = Set(items.map(\.url))
		let newLinks = links.filter { existingURLs.contains($0.url.absoluteString) == false }
		guard newLinks.isEmpty == false else { return }

		await setLoading(true)
		if let attachments = try? await AttachmentFactory.createLinkAttachments(from: newLinks) {
			Task { @MainActor in
				var text = inputText.text
				newLinks.forEach { each in
					text = text.replace(each.url.absoluteString, with: "")
				}
				self.inputText.text = text
				setLoading(false)
				self.attachments.append(contentsOf: attachments)
			}
		} else {
			await setLoading(false)
		}
	}

	@concurrent
	func parseImages(selectedImages: [SelectedImage]) async {
		await setLoading(true)
		var items = await self.attachments
		var pickerItems = selectedImages
		let pickerIDs = Set(pickerItems.map(\.id))
		items.removeAll { pickerIDs.contains($0.uid) == false }
		pickerItems.removeAll { item in items.contains { $0.uid == item.id } }

		let newItems = try? await AttachmentFactory.createImageAttachments(
			from: pickerItems)
		if let newItems {
			items.append(contentsOf: newItems)
		}
		Task { @MainActor in
			setLoading(false)
			self.attachments = items
			if !items.isEmpty {
				self.source = .liary
			}
		}
	}

	@concurrent
	func generateImage(prompt: String) async throws {
		guard prompt.isWhitespace == false else { return }
		await setLoading(true)
		let imageCreator = try await ImageCreator()
		let createdImages = imageCreator.images(
			for: [.text(prompt)],
			style: .animation,
			limit: 1)

		var image: UIImage?
		for try await created in createdImages {
			image = UIImage(cgImage: created.cgImage)
		}
		guard let image else {
			await setLoading(false)
			return
		}
		let attachment = try await AttachmentFactory.createImageAttachment(from: image)
		Task { @MainActor in
			setLoading(false)
			inputText.clear()
			self.attachments.append(attachment)
		}
	}

	func removeAttachment(id: String) {
		attachments.removeAll { $0.id == id }
		self.photoPicker.remove(for: id)
	}
}
