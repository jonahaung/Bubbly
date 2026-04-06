
import Database
import Services
import SwiftUI

extension ChatManager: ScrollCoordinatorDelegate {

	private var isPaginatonEnabled: Bool {
		conversationConfig.canPaginate
	}

	func scrollCoordinator(
		_ coordinator: ScrollCoordinator,
		shouldPaginateAt edge: VerticalEdge,
	) -> Bool {
		guard isPaginatonEnabled else {
			return false
		}

		switch edge {
		case .top:
			guard let id = conversationConfig.firstMsgID else {
				return false
			}
			return !models.contains(withID: id)

		case .bottom:
			guard let id = conversationConfig.lastMsgID else {
				return false
			}
			return !models.contains(withID: id)
		}
	}

	func scrollCoordinatorShouldRemove(_ coordinator: ScrollCoordinator) -> Bool {
		isPaginatonEnabled && models.count > conversationConfig.pageSize * 2
	}

	func scrollCoordinator(
		_ coordinator: ScrollCoordinator,
		finalizeUpdate _: ScrollCoordinator.State,
		newState: ScrollCoordinator.State,
	) {
		presentation.send(
			.bottomAccessory(
				newState.scrolledPosition == .atBottom ? nil : .scrollDownButton,
			),
		)
		if newState.scrolledPosition == .atBottom, models.count > conversationConfig.pageSize * 2 {
			models.retainNewest(conversationConfig.pageSize)
			layoutIfNeeded()
		}
	}

	func scrollCoordinator(
		_ coordinator: ScrollCoordinator,
		paginateAt edge: VerticalEdge,
	) {
		guard coordinator.updatedState(is: .willBeginUpdates) else {
			return
		}

		serialQueue.addOperation(priority: .userInitiated, barrier: true) { [weak self] in
			guard let self else {
				return
			}

			let message = edge == .top ? oldestMessage : newestMessage
			guard let message else {
				scrollController.updateStateUpdate(to: .didEndUpdates)
				return
			}

			let query = ServerTime(message.date).value

			let msgs =
				switch edge {
				case .top:
					try await datasource.previous(before: query, conID: message.conID)
				case .bottom:
					try await datasource.more(after: query, conID: message.conID)
				}

			if edge == .top {
				models.prepend(msgs)
			} else {
				models.append(msgs)
			}

			coordinator.updateStateUpdate(to: .insertingItems(edge))

			if edge == .bottom {
				withAnimation { layoutIfNeeded() }
			} else {
				layoutIfNeeded()
			}
		}
	}

	func scrollCoordinator(
		_ coordinator: ScrollCoordinator,
		removeAt edge: VerticalEdge,
	) {
		guard coordinator.updatedState(is: .willBeginUpdates) else {
			return
		}

		serialQueue.addOperation(priority: .userInitiated, barrier: true) { [weak self] in
			guard let self else {
				return
			}

			let limit = conversationConfig.pageSize * 2

			if edge == .top {
				models.retainNewest(limit)
			} else {
				models.retainOldest(limit)
			}

			coordinator.updateStateUpdate(to: .removingItems(edge))

			if edge == .bottom {
				withAnimation { layoutIfNeeded() }
			} else {
				layoutIfNeeded()
			}
		}
	}

	func reloadScrollView(for _: ScrollCoordinator) {
		layoutIfNeeded()
	}
}

extension ChatManager {

	var newestMessage: Database.Message? {
		models.last?.msg
	}

	var oldestMessage: Database.Message? {
		models.first?.msg
	}

	func reloadData() {
		layoutIfNeeded()
	}

	func scrollTo(msgID: String?) {
		scrollController.updateStateUpdate(to: .willBeginUpdates)
		serialQueue.addOperation { [weak self] in
			guard let self else {
				return
			}
			let query: String
			if let msgID {
				guard let msg = try await Store.shared.msgStore?.fetch(uid: msgID) else {
					query = ServerTime(.now).value
					return
				}
				query = ServerTime(msg.date).value
			} else {
				query = ServerTime(.now).value
			}

			let msgs = try await datasource.msg(
				from: query,
				conID: conversationConfig.conID,
			)
			models.set(msgs: msgs)
			withTransaction(.scrollView(completion: { [weak self] in
				guard let self else {
					return
				}
				if let msgID {
					scrollController
						.enqueueScroll(to: .id(msgID, properties: .animated(.interpolatingSpring)))
				} else {
					scrollController
						.performScroll(to: .snapToBottom())
				}
				scrollController.updateStateUpdate(to: .didEndUpdates)
			})) {
				layoutIfNeeded()
			}
		}
	}
}
