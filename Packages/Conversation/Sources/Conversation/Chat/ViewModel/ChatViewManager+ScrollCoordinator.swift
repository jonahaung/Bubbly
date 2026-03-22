//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Services
import SwiftUI

extension ChatViewManager: ScrollCoordinatorDelegate {

	private var isPaginatorEnabled: Bool {
		conversationConfig.canPaginate
	}

	func scrollCoordinator(
		_ coordinator: ScrollCoordinator,
		shouldPaginateAt edge: VerticalEdge
	) -> Bool {
		guard isPaginatorEnabled else { return false }
		switch edge {
		case .top:
			return canLoadOlderMessages
		case .bottom:
			return canLoadNewerMessages
		}
	}

	func scrollCoordinatorShouldRemove(_ coordinator: ScrollCoordinator) -> Bool {
		guard isPaginatorEnabled else { return false }
		return models.count > conversationConfig.pageSize * 2
	}

	func scrollCoordinator(
		_ coordinator: ScrollCoordinator,
		finalizeUpdate state: ScrollCoordinator.State,
		newState: ScrollCoordinator.State
	) {
		presentation
			.send(.bottomAccessory(newState.geometry.isNear(.bottom) ? nil : .scrollDownButton))
	}

	func scrollCoordinator(_ coordinator: ScrollCoordinator, paginateAt edge: VerticalEdge) {
		guard coordinator.updatedState(is: .willBeginUpdates) else { return }
		switch edge {
		case .top:
			serialQueue.addOperation { [weak self] in
				guard let self else { return }
				guard let oldestMessage else {
					revertState()
					return
				}
				let query = ServerTime(oldestMessage.date).value
				let msgs = try await datasource.loadPrevious(
					before: query,
					conID: oldestMessage.conID
				)
				models.prepend(msgs)
				coordinator.updateStateUpdate(to: .insertingItems(edge))
				layoutIfNeeded()
			}

		case .bottom:
			serialQueue.addOperation { [weak self] in
				guard let self else { return }
				guard let newestMessage else {
					revertState()
					return
				}
				let query = ServerTime(newestMessage.date).value
				let msgs = try await datasource.loadMore(
					after: query,
					conID: newestMessage.conID
				)
				models.append(msgs)
				coordinator.updateStateUpdate(to: .insertingItems(edge))
				withAnimation {
					layoutIfNeeded()
				}
			}
		}

		func revertState() {
			scrollController.updateStateUpdate(to: .didEndUpdates)
		}
	}

	func scrollCoordinator(_ coordinator: ScrollCoordinator, removeAt edge: VerticalEdge) {
		guard coordinator.updatedState(is: .willBeginUpdates) else { return }
		serialQueue.addOperation { [weak self] in
			guard let self else { return }
			let pageSize = conversationConfig.pageSize
			switch edge {
			case .top:
				models.retainNewest(pageSize*2)
				coordinator.updateStateUpdate(to: .removingItems(edge))
				layoutIfNeeded()
			case .bottom:
				models.retainOldest(pageSize*2)
				coordinator.updateStateUpdate(to: .removingItems(edge))
				withAnimation {
					layoutIfNeeded()
				}
			}
		}
	}

	func reloadScrollView(for _: ScrollCoordinator) {
		layoutIfNeeded()
	}

	func scrollCoordinator(_ coordinator: ScrollCoordinator, resetAt edge: VerticalEdge) {
		coordinator.updateStateUpdate(to: .resetting)
		resetData()
	}
}

extension ChatViewManager {
	var newestMessage: Database.Message? {
		models.last?.msg
	}

	var oldestMessage: Database.Message? {
		models.first?.msg
	}

	var canLoadOlderMessages: Bool {
		guard isPaginatorEnabled else { return false }
		guard let firstMsgID = conversationConfig.firstMsgID else { return false }
		guard !models.isEmpty else { return false }
		return !models.contains(withID: firstMsgID)
	}

	var canLoadNewerMessages: Bool {
		guard isPaginatorEnabled else { return false }
		guard let lastMsgID = conversationConfig.lastMsgID else { return false }
		guard !models.isEmpty else { return false }
		return !models.contains(withID: lastMsgID)
	}

	var canResetDatasource: Bool {
		guard isPaginatorEnabled else { return false }
		return canLoadNewerMessages
	}

	func reloadData() {
		layoutIfNeeded()
	}
	func resetData() {
		serialQueue.addOperation { [weak self] in
			guard let self else { return }
			let msgs = try await datasource.reset(conID: conversationConfig.conID)
			models.set(msgs: msgs)
			layoutIfNeeded()
		}
	}
}
