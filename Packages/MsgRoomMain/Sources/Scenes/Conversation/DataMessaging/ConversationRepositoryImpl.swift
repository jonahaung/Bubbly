import Core
import Database
import Services
import SwiftUI

@MainActor
struct ConversationRepositoryImpl: ConversationRepository {
	private let manager: ChatViewManager
	private let composer: ChatComposer
	private let currentUserID: String

	init(manager: ChatViewManager, composer: ChatComposer, currentUserID: String) {
		self.manager = manager
		self.composer = composer
		self.currentUserID = currentUserID
	}

	func observeConversation() async throws -> ConversationSnapshot {
		try await manager.onViewAppear()
		return snapshot()
	}

	func sendMessage(_ text: String) async throws -> ConversationSnapshot {
		let attachments = composer.attachments
		try await composer.send(
			text: text.trimmed,
			attachments: attachments,
			conversation: manager.conversation
		)
		composer.resetDraft()
		return snapshot()
	}

	func loadMoreMessages() async -> ConversationSnapshot {
		manager.resetDatasource()
		return snapshot()
	}

	func retryMessage(_ text: String) async throws -> ConversationSnapshot {
		try await sendMessage(text)
	}

	func closeConversation() async {
		await manager.saveConversationChanges()
	}

	func openConversationDetails() async {
		Router.shared.pushToNav(.conversationDetails(manager.conversation))
	}

	func updateComposerSource(_ source: ChatComposer.Source) async -> ConversationSnapshot {
		composer.updateSource(source)
		return snapshot()
	}

	func appendEmoji(_ emoji: String) async -> ConversationSnapshot {
		composer.inputText.text.append(emoji)
		composer.inputText.selectAll()
		composer.source = .text
		return snapshot()
	}

	func selectMessage(_ uid: String) async -> ConversationSnapshot {
		manager.setSelectedMsg(uid)
		return snapshot()
	}

	func openAvatar(for id: String) async {
		guard let viewModel = manager.models.element(withID: id),
		      let contact = viewModel.sender()
		else {
			return
		}
		guard let url = DeepLinkCoordinator.shared.url(for: .profile(id: contact.uid)) else {
			return
		}
		await UIApplication.shared.open(url)
	}

	func markMessage(_ message: Message) async {
		manager.presentation.updateToast(.message(message))
	}

	func focusMsgBubble(_ item: ChatOverlayView.Item?) async -> ConversationSnapshot {
		manager.presentation.updateFocusedFrame(item)
		return snapshot()
	}

	func sendUploadedMessage(_ message: Message) async -> ConversationSnapshot {
		await Socket.send(.newMsg(rMsg: .init(message)), conversation: manager.conversation)
		return snapshot()
	}

	func react(to message: Message, reaction: ReactionType) async throws -> ConversationSnapshot {
		try await Task.sleep(seconds: 1)
		let payload = Reaction(
			rawValue: reaction.rawValue,
			senderID: currentUserID,
			date: .now
		)
		await Socket.send(
			.reaction(
				reaction: .init(
					reaction: payload,
					msgID: message.uid,
					conID: manager.conversation.uid
				)
			),
			conversation: manager.conversation
		)
		manager.presentation.updateFocusedFrame(nil)
		return snapshot()
	}

	func latestSnapshot() async -> ConversationSnapshot {
		snapshot()
	}

	private func snapshot() -> ConversationSnapshot {
		ConversationSnapshot(
			messages: manager.models.msgs(),
			conversation: manager.conversation,
			selectedMsg: manager.presentation.selectedMsg,
			overlayItem: manager.presentation.overlayItem,
			reloadID: manager.reloadID
		)
	}
}
