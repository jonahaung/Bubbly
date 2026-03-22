//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
final class ChatViewManager: ErrorPresenter {

	struct State: Equatable {
		var reloadID: Int
		var conversation: Conversation
		var theme: ChatTheme
		var properties: ConversationProperties
	}

	@ObservationIgnored let datasource: ChatDatasource
	@ObservationIgnored let scrollController: ScrollCoordinator
	@ObservationIgnored let presentation: ChatPresentationState
	@ObservationIgnored let conversationConfig: ConversationInitializer.Configuration
	@ObservationIgnored let attachmentFetcher: AttachmentFetcher
	@ObservationIgnored let models: MsgModels
	@ObservationIgnored let serialQueue = AsyncQueue(attributes: [.concurrent])
	@ObservationIgnored let layout = ChatViewLayout()
	@ObservationIgnored private let throttler = XUI.Throttler(delay: 1, option: .leading)

	var state: State
	var conversation: Conversation { state.conversation }

	init(_ data: ConversationInitializer.PrefetchedData) {
		conversationConfig = data.configuration
		datasource = .init(data.configuration)
		scrollController = .init()
		presentation = .init(data.configuration)
		attachmentFetcher = .init()
		models = .init(data.msgs)
		state = .init(
			reloadID: 0,
			conversation: data.conversation,
			theme: .init(data.properties.theme),
			properties: data.properties
		)
		scrollController.delegate = self
		datasource.delegate = self
	}

	deinit {
		log("Deinit")
	}
}

extension ChatViewManager {
	func layoutIfNeeded() {
		state.reloadID += 1
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

	func onScrollTargetVisibilityChange(_ newValue: [String]) {
		throttler.throttle { [weak self] in
			guard let self else { return }
			let oldValues = presentation.visibleIDs
			let differences = newValue.difference(from: oldValues)
			var newIDs = [String]()
			differences.forEach { difference in
				switch difference {
				case .insert(_, let element, _):
					models.didChangeVisibility(for: element, isVisible: true)
					newIDs.append(element)
				case .remove(_, let element, _):
					models.didChangeVisibility(for: element, isVisible: false)
				}
			}
			presentation.visibleIDs = newValue
			if let last = newValue.last, let date = models.element(withID: last)?.msg.date {
				presentation.send(.date(date))
			}
		}
	}

	func handleScrollDownButtonTap() {
		if canResetDatasource {
			scrollController.handleResetData()
		} else {
			scrollController
				.enqueueScroll(
					to: .edge(.bottom, properties: .animated(.interpolatingSpring(duration: 0.3)))
				)
		}
	}

	func setSelectedMsg(_ uid: String) {
		guard let index = models.index(of: uid) else { return }
		let oldValue = layout.selectedMsg

		let nextMsg = models[safe: index + 1]?.msg
		let previousMsg = models[safe: index - 1]?.msg
		let newValue: SelectedMsg? =
			oldValue?.id == uid
			? nil
			: SelectedMsg(
				id: uid,
				previous: previousMsg?.uid,
				next: nextMsg?.uid
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

	func onViewAppear() async {
		try? await reloadConversation(refetch: true)
		updateReceiveMsgs()
	}
	func onViewDisappear() {
		serialQueue.cancel()
		throttler.cancel()
		scrollController.send(.onVisibilityChange(visibility: .hidden))
	}
}
