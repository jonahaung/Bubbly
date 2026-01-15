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
final class ChatComposer: ErrorPresenter, ViewReloadable {

	@ObservationIgnored var inputText = InputText()
	@ObservationIgnored var photoPicker = PhotoPickerManager()

	var attachments = [Attachment]()
	var composeType = ComposeSource.text
	var menuVisibility = Visibility.visible
	var isLoading: Bool = false

	private let msgCreater: MsgCreator

	var reloadID: Int = 0

	init() {
		msgCreater = .init(currentUserId: currentUserId ?? "")
		inputText.delegate = self
		photoPicker.delegate = self
		trackItemsChanges()
	}
	deinit {
		Log("")
	}

	var hasContent: Bool {
		inputText.hasText || !attachments.isEmpty
	}

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
		if menuVisibility == .visible && !text.isWhitespace {
			menuVisibility = .hidden
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
	func send(conversation: Conversation) {
		let text = inputText.text.trimmed
		let attachments = self.attachments
		guard !text.isWhitespace || !attachments.isEmpty else {
			inputText.text = Lorem.random()
			return
		}
		switch composeType {
		case .text:
			internalSend()
		case .camera:
			internalSend()
		case .liary:
			internalSend()
		case .audio:
			internalSend()
		case .document:
			internalSend()
		case .machineImag:
			Task {
				try await generateImage(prompt: text)
			}
		}
		func internalSend() {
			reset()
			Task {
				do {
					try await send(text: text, attachments: attachments, conversation: conversation)
				} catch {
					await self.showError(error)
				}
			}
		}
	}

	func send(msg: ChatEngineMsgGenerable, conversation: Conversation) async throws {
		let msg = try await msgCreater.message(
			text: msg.content,
			attachments: [],
			in: conversation
		)
		try await Socket.shared.send(.newMsg(rMsg: .init(msg)), conversation: conversation)
	}
	@concurrent func send(text: String, attachments: [Attachment], conversation: Conversation) async throws {
		var msg = try await msgCreater.message(
			text: text,
			attachments: attachments,
			in: conversation
		)
		if attachments.isEmpty == false, var text = msg.text {
			if text == attachments.first?.url {
				msg.text = nil
			} else {
				attachments.forEach { each in
					if text
						.contains(each.url), let url = URL(string: each.url), let host = url.host()?.replace(
							"www.",
							with: ""
						) {
						text = text.replace(each.url, with: "[\(host)](\(each.url))")
					}
				}
				msg.text = text
			}
		}

		if msg.attachments.contains(where: { $0.attachmentType == .imageUploading }) {
			await Socket.shared.notifyMessage(.newMsg(rMsg: .init(msg)))
		} else {
			try await Socket.shared.send(.newMsg(rMsg: .init(msg)), conversation: conversation)
		}
	}

	private func reset() {
		inputText.clear()
		attachments.removeAll()
		photoPicker.removeAll()
	}
}

private extension ChatComposer {
	func trackItemsChanges() {
		withObservationTracking {
			_ = composeType
			_ = menuVisibility
		} onChange: { [weak self] in
			guard let self else { return }
			Task {
				await layoutIfNeeded()
				await trackItemsChanges()
			}
		}
	}
}
extension ChatComposer {
	@concurrent
	func parseLinks(links: [ExtractedLink]) async {
		let items = await self.attachments
		let newLinks = links.filter { link in
			items.contains { attachment in
				attachment.url == link.url.absoluteString
			} == false
		}
		guard newLinks.isEmpty == false else { return }
		await setLoading(true)
		if let attachments = try? await AttachmentFactory.createLinkAttachments(from: newLinks) {
			await MainActor.run {
				setLoading(false)
				self.attachments.append(contentsOf: attachments)
			}
		}
	}

	@concurrent
	func parseImages(selectedImages: [SelectedImage]) async {
		await setLoading(true)
		var items = await self.attachments
		var pickerItems = selectedImages
		items.forEach { each in
			if !pickerItems.contains(where: { $0.id == each.uid }) {
				if let index = items.firstIndex(where: { $0.uid == each.uid }) {
					items.remove(at: index)
				}
			}
		}
		pickerItems.forEach { each in
			if items.contains(where: { $0.uid == each.id }) {
				if let index = pickerItems.firstIndex(where: { $0.id == each.id }) {
					pickerItems.remove(at: index)
				}
			}
		}
		let newItems = try? await AttachmentFactory.createImageAttachments(
			from: pickerItems)
		if let newItems {
			items.append(contentsOf: newItems)
		}
		await MainActor.run {
			setLoading(false)
			self.attachments = items
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
		await MainActor.run {
			setLoading(false)
			inputText.clear()
			self.attachments.append(attachment)
		}
	}

	func removeAttachment(id: String) {
		attachments.removeAll{ $0.id == id }
		self.photoPicker.remove(for: id)
	}
}
