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

    func scrollCoordinator(
        _: ScrollCoordinator,
        finalizeUpdate _: ScrollCoordinator.State,
        newState: ScrollCoordinator.State,
    ) {
        presentation.send(
            .bottomAccessory(
                newState.scrolledPosition == .atBottom ? nil : .scrollDownButton,
            ),
        )

        if newState.scrolledPosition == .atBottom, models.count > conversationConfig.pageSize * 2 {
            serialQueue.addOperation(priority: .userInitiated, barrier: true) { [weak self] in
                guard let self else {
                    return
                }

                models.retainNewest(conversationConfig.pageSize)
                layoutIfNeeded()
            }
        }
    }

    func scrollCoordinator(
        _ coordinator: ScrollCoordinator,
        paginateAt edge: VerticalEdge,
    ) {
        guard coordinator.updatedState(is: .willBeginUpdates) else {
            return
        }

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
                    try await datasource.previous(before: query, conID: message.conID)
                case .bottom:
                    try await datasource.more(after: query, conID: message.conID)
                }

            let noMorePrevious = msgs.contains(
                where: { $0.uid == conversationConfig.firstMsgID },
            )
            if models.headerModels.isEmpty {
                if noMorePrevious {
                    models.headerModels.append(.init(kind: .conversation(state.conversation)))
                }
            } else {
                if !noMorePrevious {
                    models.headerModels.removeAll()
                }
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

        serialQueue.addOperation { [weak self] in
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
        }
        serialQueue.addBarrierOperation { @MainActor [weak self] in
            guard let self else {
                return
            }

            withTransaction(.scrollView()) {
                layoutIfNeeded()
            }
            scrollController.performScroll(to: .nearBottom(100))
            try await Task.sleep(seconds: 0.1)
        }
        serialQueue.addOperation(priority: .high, barrier: true) { @MainActor [weak self] in
            guard let self else {
                return
            }

            scrollController.performScroll(to: .edge(.bottom, properties: .animated()))
        }
        serialQueue.addOperation { [weak self] in
            guard let self else {
                return
            }

            scrollController.updateStateUpdate(to: .didEndUpdates)
        }
    }
}
