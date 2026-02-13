import Core
import Database
import ImagePlayground
import MediaPicker
import Services
import SwiftUI
import XUI

@MainActor
@Observable
final class ChatComposer: ErrorPresenter, Equatable {
	@ObservationIgnored var inputText = InputText()
	@ObservationIgnored var photoPicker = PhotoPickerManager()
	@ObservationIgnored private let msgCreator: MsgCreator
	@ObservationIgnored private let id: String
	@ObservationIgnored private let worker = ChatComposerWorker()
	@ObservationIgnored private let stateStore = ChatComposerStateStore()

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

	func updateSource(_ source: ChatComposer.Source) {
		Task {
			let snapshot = await stateStore.toggleSource(current: self.source, requested: source)
			await MainActor.run {
				self.applySnapshot(snapshot)
			}
			await worker.playTone(.tap1)
		}
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
	func inputText(_: InputText, didInsertLinks links: [ExtractedLink]) {
		Task {
			await parseLinks(links: links)
		}
	}

	func inputText(_ inputText: InputText, didBeganEditing text: String) {
		if text.isEmpty {
			Task {
				let snapshot = await stateStore.resetAttachments()
				await MainActor.run {
					self.applySnapshot(snapshot)
				}
			}
		} else {
			inputText.selection = nil
			Task {
				let snapshot = await stateStore.setSource(.text)
				await MainActor.run {
					self.applySnapshot(snapshot)
				}
			}
		}
	}
}

extension ChatComposer: PhotoPickerManagerDelegate {
	func photoPickerManager(_: PhotoPickerManager,
	                        didSelectImages images: [MediaPicker.SelectedImage])
	{
		Task {
			await parseImages(selectedImages: images)
		}
	}
}

extension ChatComposer {
	func handlePrimaryAction(_ conversation: Conversation) {
		let text = inputText.text
		if text.isWhitespace, attachments.isEmpty {
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
		Task {
			let snapshot = await stateStore.setSource(.text)
			await MainActor.run {
				self.applySnapshot(snapshot)
			}
		}
	}

	func send(conversation: Conversation) {
		let text = inputText.text.trimmed
		if text.isWhitespace {
			inputText.text = Lorem.random()
			return
		}
		Task {
			let snapshot = await stateStore.snapshot()
			await MainActor.run {
				self.resetDraft()
			}
			await worker.playTone(.tap1)
			do {
				try await send(
					text: text,
					attachments: snapshot.attachments,
					conversation: conversation
				)
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
		await Socket.send(.newMsg(rMsg: .init(msg)), conversation: conversation)
	}

	@concurrent func send(text: String,
	                      attachments: [Attachment],
	                      conversation: Conversation) async throws
	{
		try await worker.sendMessage(
			text: text,
			attachments: attachments,
			conversation: conversation,
			msgCreator: msgCreator
		)
	}

	func resetDraft() {
		inputText.clear()
		photoPicker.removeAll()
		Task {
			let snapshot = await stateStore.reset()
			await MainActor.run {
				self.applySnapshot(snapshot)
			}
		}
	}
}

extension ChatComposer {
	@concurrent
	func parseLinks(links: [ExtractedLink]) async {
		let existingURLs = await stateStore.attachmentURLs()
		let newLinks = links.filter { existingURLs.contains($0.url.absoluteString) == false }
		guard newLinks.isEmpty == false else { return }

		await MainActor.run { self.setLoading(true) }
		if let attachments = await worker.makeLinkAttachments(from: newLinks) {
			let snapshot = await stateStore.appendAttachments(attachments)
			await MainActor.run {
				var text = self.inputText.text
				for each in newLinks {
					text = text.replace(each.url.absoluteString, with: "")
				}
				self.inputText.text = text
				self.setLoading(false)
				self.applySnapshot(snapshot)
			}
		} else {
			await MainActor.run { self.setLoading(false) }
		}
	}

	@concurrent
	func parseImages(selectedImages: [SelectedImage]) async {
		await MainActor.run { self.setLoading(true) }
		let snapshot = await stateStore.processSelectedImages(
			selectedImages: selectedImages,
			worker: worker
		)
		await MainActor.run {
			self.setLoading(false)
			self.applySnapshot(snapshot)
		}
	}

	@concurrent
	func generateImage(prompt: String) async throws {
		guard prompt.isWhitespace == false else { return }
		await MainActor.run { self.setLoading(true) }
		if let attachment = try await worker.makeGeneratedImageAttachment(prompt: prompt) {
			let snapshot = await stateStore.appendAttachments([attachment])
			await MainActor.run {
				self.inputText.clear()
				self.applySnapshot(snapshot)
				self.setLoading(false)
			}
		} else {
			await MainActor.run { self.setLoading(false) }
		}
	}

	func removeAttachment(id: String) {
		photoPicker.remove(for: id)
		Task {
			let snapshot = await stateStore.removeAttachment(id: id)
			await MainActor.run {
				self.applySnapshot(snapshot)
			}
		}
	}

	private func applySnapshot(_ snapshot: ChatComposerSnapshot) {
		attachments = snapshot.attachments
		source = snapshot.source
	}
}

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

	func sendMessage(text: String,
	                 attachments: [Attachment],
	                 conversation: Conversation,
	                 msgCreator: MsgCreator) async throws
	{
		let sanitizedText = sanitizeText(text, attachments: attachments)
		let msg = try await msgCreator.message(
			text: sanitizedText,
			attachments: attachments,
			in: conversation
		)
		if msg.attachments.contains(where: { $0.attachmentType == .imageUploading }) {
			await Socket.shared.notifyMessage(.newMsg(rMsg: .init(msg)))
		} else {
			await Socket.send(.newMsg(rMsg: .init(msg)), conversation: conversation)
		}
	}

	private func sanitizeText(_ text: String, attachments: [Attachment]) -> String {
		guard attachments.isEmpty == false else { return text }
		var updated = text
		if updated == attachments.first?.url {
			return ""
		}
		for each in attachments {
			updated = updated.replace(each.url, with: "")
		}
		return updated.trimmed
	}

	func playTone(_ tone: Tone) {
		TonePlayer.play(tone)
	}
}

private struct ChatComposerSnapshot: Sendable {
	let attachments: [Attachment]
	let source: ChatComposer.Source
}

private actor ChatComposerStateStore {
	private var attachments: [Attachment] = []
	private var source: ChatComposer.Source = .text

	func snapshot() -> ChatComposerSnapshot {
		.init(attachments: attachments, source: source)
	}

	func attachmentURLs() -> Set<String> {
		Set(attachments.map(\.url))
	}

	func toggleSource(current: ChatComposer.Source, requested: ChatComposer.Source)
		-> ChatComposerSnapshot
	{
		if current == requested {
			source = .menu
		} else {
			source = requested
		}
		return snapshot()
	}

	func setSource(_ value: ChatComposer.Source) -> ChatComposerSnapshot {
		source = value
		return snapshot()
	}

	func reset() -> ChatComposerSnapshot {
		attachments.removeAll()
		source = .text
		return snapshot()
	}

	func resetAttachments() -> ChatComposerSnapshot {
		attachments.removeAll()
		return snapshot()
	}

	func appendAttachments(_ newItems: [Attachment]) -> ChatComposerSnapshot {
		attachments.append(contentsOf: newItems)
		if attachments.isEmpty == false {
			source = .liary
		}
		return snapshot()
	}

	func removeAttachment(id: String) -> ChatComposerSnapshot {
		attachments.removeAll { $0.id == id }
		if attachments.isEmpty {
			source = .text
		}
		return snapshot()
	}

	func processSelectedImages(selectedImages: [SelectedImage],
	                           worker: ChatComposerWorker) async -> ChatComposerSnapshot
	{
		var items = attachments
		var pickerItems = selectedImages
		let pickerIDs = Set(pickerItems.map(\.id))
		items.removeAll { pickerIDs.contains($0.uid) == false }
		pickerItems.removeAll { item in items.contains { $0.uid == item.id } }

		if let newItems = await worker.makeImageAttachments(from: pickerItems) {
			items.append(contentsOf: newItems)
		}

		attachments = items
		if attachments.isEmpty == false {
			source = .liary
		}
		return snapshot()
	}
}
