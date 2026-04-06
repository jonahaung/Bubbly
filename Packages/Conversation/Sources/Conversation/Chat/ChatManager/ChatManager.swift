//
// Created by Aung Ko Min
//

import Combine
import Core
import Database
import ImageLoader
import Services
import SwiftUI
import XUI

@MainActor
@Observable
final class ChatManager: ErrorPresenter {

	// MARK: Lifecycle

	init(_ data: ConversationInitializer.PrefetchedData) {
		conversationConfig = data.configuration
		datasource = .init(pageSize: data.configuration.pageSize)
		models = .init(data.msgs)
		scrollController = .init()
		presentation = .init(data.configuration)
		dataObserver = .init(conID: data.configuration.conID)
		attachmentFetcher = .init()
		state = .init(
			reloadID: 0,
			conversation: data.conversation,
			theme: .init(data.properties.theme),
			properties: data.properties,
		)
		dataObserver.delegate = self
		scrollController.delegate = self
	}

	deinit {
		log("Deinit")
	}

	// MARK: Internal

	struct State: Equatable {
		var reloadID: Int
		var conversation: Conversation
		var theme: ChatTheme
		var properties: ConversationProperties
	}

	@ObservationIgnored let datasource: ChatDatasource
	@ObservationIgnored let scrollController: ScrollCoordinator
	@ObservationIgnored var presentation: ChatPresentationState
	@ObservationIgnored let conversationConfig: ConversationInitializer.Configuration
	@ObservationIgnored let attachmentFetcher: AttachmentFetcher
	@ObservationIgnored let models: MsgModels
	@ObservationIgnored let serialQueue: AsyncQueue = .init()
	@ObservationIgnored let layout: ChatViewLayout = .init()
	@ObservationIgnored let dataObserver: ChatDataObserver

	var state: State

}

extension ChatManager {
	func layoutIfNeeded() {
		state.reloadID = state.reloadID == 0 ? 1 : 0
	}

	func onBottomBarFrameChage(_ oldValue: CGRect, _ newValue: CGRect) {
		if layout.bottomBarFrame == nil, newValue.origin.x >= 0 {
			layout.update(bottomBarFrame: newValue)
		} else {
			scrollController.send(.onBottomBarFrameChage(oldValue, newValue))
		}

	}

	func send(_ intent: ScrollCoordinator.Intent) {
		scrollController.send(intent)
	}

	func handleScrollDownButtonTap() {
		if scrollCoordinator(scrollController, shouldPaginateAt: .bottom) {
			scrollTo(msgID: nil)
		} else {
			scrollController
				.performScroll(to: .edge(.bottom, properties: .animated(.interpolatingSpring)))
		}
	}

	func setSelectedMsg(_ uid: String) {
		guard let index = models.index(of: uid) else {
			return
		}
		let oldValue = layout.selectedMsg
		let nextMsg = models[safe: index + 1]?.msg
		let previousMsg = models[safe: index - 1]?.msg
		let newValue: SelectedMsg? =
			oldValue?.id == uid
				? nil
				: SelectedMsg(
					id: uid,
					previous: previousMsg?.uid,
					next: nextMsg?.uid,
				)

		withAnimation(.interactiveSpring) {
			if let oldValue {
				models.didChangeSelection(newValue, for: oldValue.id)
			}
			if let newValue {
				models.didChangeSelection(newValue, for: newValue.id)
			}
			layoutIfNeeded()
		} completion: { [self] in
			layout.selectedMsg = newValue
			if let oldValue {
				if let id = oldValue.next {
					models.didChangeSelection(newValue, for: id)
				}
				if let id = oldValue.previous {
					models.didChangeSelection(newValue, for: id)
				}
			}
			if let newValue {
				if let id = newValue.next {
					models.didChangeSelection(newValue, for: id)
				}
				if let id = newValue.previous {
					models.didChangeSelection(newValue, for: id)
				}
			}
		}
	}

	func onViewAppear() {
		Router.shared.setTabBar(visibility: .hidden)
		Task.detached { [weak self] in
			guard let self else {
				return
			}
			try? await reloadConversation(refetch: true)
			await updateReceiveMsgs()
		}
	}

	func onViewDisappear() {
		log("onViewDisappear")
	}
}
