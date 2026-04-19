// © 2026 Aung Ko Min

import Database
import Services
import SwiftUI

// MARK: - ChatManager + ScrollCoordinatorDelegate

extension ChatManager: ScrollCoordinatorDelegate {
    
    func edgeMsg(at edge: VerticalEdge) -> Database.Message? {
        switch edge {
        case .top:
            models.first?.msg
        case .bottom:
            models.last?.msg
        }
    }

    private var isPaginatonEnabled: Bool {
        conversationConfig.canPaginate
    }

    func scrollCoordinator(
        _: ScrollCoordinator,
        shouldPaginateAt edge: VerticalEdge,
    ) -> Bool {
        guard isPaginatonEnabled else {
            return false
        }

        switch edge {
        case .top:
            guard let firstMsgID = conversationConfig.firstMsgID else {
                return false
            }

            return !models.contains(withID: firstMsgID)

        case .bottom:
            guard let lastMsgID = conversationConfig.lastMsgID else {
                return false
            }

            return !models.contains(withID: lastMsgID)
        }
    }

    func scrollCoordinatorShouldRemove(_: ScrollCoordinator) -> Bool {
        isPaginatonEnabled && models.count > conversationConfig.pageSize * 2
    }

    func scrollCoordinator(_ coordinator: ScrollCoordinator, state: ScrollCoordinator.State) {
        presentation.send(
            .bottomAccessory(
                state.scrolledPosition == .atBottom
                    ? nil : .scrollDownButton,
            ),
        )
        models.displayVisibleMsgsIfNeeded()
    }

    func scrollCoordinator(
        _ coordinator: ScrollCoordinator,
        paginateAt edge: VerticalEdge,
    ) {
        serialQueue.addOperation { [weak self] in
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
                    try await datasource.previous(
                        before: query,
                        conID: message.conID
                    )
                case .bottom:
                    try await datasource.more(
                        after: query,
                        conID: message.conID
                    )
                }
            if edge == .top {
                await models.prepend(msgs)
                coordinator.updateStateUpdate(to: .insertingItems(edge))
                layoutIfNeeded()
            } else {
                await models.append(msgs)
                coordinator.updateStateUpdate(to: .insertingItems(edge))
                withAnimation {
                    layoutIfNeeded()
                }
            }
        }
    }

    private func configureHeader(noMorePrevious: Bool) {
        if models.headerModels.isEmpty {
            if noMorePrevious {
                models.headerModels.append(
                    .init(kind: .conversation(state.conversation))
                )
            }
        } else {
            if !noMorePrevious {
                models.headerModels = []
            }
        }
    }

    func scrollCoordinator(
        _ coordinator: ScrollCoordinator,
        removeAt edge: VerticalEdge,
    ) {

        serialQueue.addOperation { [weak self] in
            guard let self else {
                return
            }
            let limit = conversationConfig.pageSize * 2
            switch edge {
            case .top:
                await models.retainNewest(limit)
                coordinator.updateStateUpdate(to: .removingItems(edge))
                layoutIfNeeded()
            case .bottom:
                await models.retainOldest(limit)
                coordinator.updateStateUpdate(to: .removingItems(edge))
                withAnimation {
                    layoutIfNeeded()
                }
            }
        }
    }
    
    func onScrollTargetVisibilityChange(_ newValue: [String]) {
        if let dateString = models.didBecomeVisible(ids: newValue) {
            presentation.send(.date(dateString))
        }
    }
}

extension ChatManager {
    var newestMessage: Database.Message? {
        models.last?.msg
    }

    var oldestMessage: Database.Message? {
        models.first?.msg
    }
    func scrollTo(msg: Message) async {
        scrollController.updateStateUpdate(to: .willBeginUpdates)

        serialQueue.addOperation { [weak self] in
            guard let self else {
                return
            }
            let query = ServerTime(msg.date).value
            let msgs = try await datasource.msg(from: query, conID: msg.conID)
            models.set(msgs: msgs)
            scrollController.updateStateUpdate(to: .resetting(msg.uid))
            layoutIfNeeded()
        }
    }
}
