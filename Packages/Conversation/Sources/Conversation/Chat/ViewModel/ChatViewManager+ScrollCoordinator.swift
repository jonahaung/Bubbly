//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Services
import SwiftUI

extension ChatViewManager: ChatScrollCoordinatorDelegate {
    var isPaginatorEnabled: Bool {
        conversationConfig.totalMsgsCount > conversationConfig.pageSize
    }

    func scrollCoordinator(
        _ coordinator: ChatScrollCoordinator,
        shouldPaginateAt edge: VerticalEdge
    ) -> Bool {
        switch edge {
        case .top:
            canLoadOlderMessages
        case .bottom:
            canLoadNewerMessages
        }
    }

    func scrollCoordinatorShouldRemove(_ coordinator: ChatScrollCoordinator) -> Bool {
        models.count > conversationConfig.pageSize + 10
    }

    func scrollCoordinator(
        _ coordinator: ChatScrollCoordinator,
        finalizeUpdate state: ChatScrollCoordinator.State,
        newState: ChatScrollCoordinator.State
    ) {
        let newVisibleIDs = newState.visibleIDs
        let differences = newVisibleIDs.difference(from: state.visibleIDs)
        for change in differences {
            switch change {
            case let .insert(_, element, _):
                models.didChangeVisibility(for: element, isVisible: true)
            case let .remove(_, element, _):
                models.didChangeVisibility(for: element, isVisible: false)
            }
        }
        if let first = newVisibleIDs.first, let date = models.element(withID: first)?.msg.date {
            presentation.send(.date(date))
        }
        presentation
            .send(.bottomAccessory(newState.geometry.isNear(.bottom) ? nil : .scrollDownButton))
        if newState.geometry.scrolledPosition == .atBottom {
            resetDatasourceIfNeeded()
        }
    }

    func scrollCoordinator(_ coordinator: ChatScrollCoordinator, paginateAt edge: VerticalEdge) {
        guard coordinator.updateState(is: .insertingItems(edge)) else { return }
        switch edge {
        case .top:
            guard let oldestMessage else {
                revertState()
                return
            }
            let query = ServerTime(oldestMessage.date).value
            Task {
                do {

                    let msgs = try await messageSource.loadPrevious(
                        before: query,
                        conID: oldestMessage.conID
                    )
                    await reloadData(with: msgs, forceReset: false)
                } catch {
                    revertState()
                    await self.showError(error)
                }
            }
        case .bottom:
            guard let newestMessage else {
                revertState()
                return
            }
            let query = ServerTime(newestMessage.date).value
            Task {
                do {
                    let msgs = try await self.messageSource.loadMore(
                        after: query,
                        conID: newestMessage.conID
                    )
                    await reloadData(with: msgs, forceReset: false)
                } catch {
                    revertState()
                    await self.showError(error)
                }
            }
        }

        func revertState() {
            scrollController.updateStateUpdate(to: .notUpdating)
        }
    }

    func scrollCoordinator(_ coordinator: ChatScrollCoordinator, removeAt edge: VerticalEdge) {
        guard coordinator.updateState(is: .removingItems(edge)) else { return }

        switch edge {
        case .top:
            let pageSize = max(1, conversationConfig.pageSize)
            let trimCount = pageSize >= 2 ? pageSize - pageSize / 2 : 1

            if models.count >= pageSize * 2 {
                models.retainNewest(pageSize)
            } else {
                models.retainNewest(trimCount)
            }
            layoutIfNeeded()
        case .bottom:
            let pageSize = max(1, conversationConfig.pageSize)
            let trimCount = pageSize >= 2 ? pageSize - pageSize / 2 : 1
            if models.count >= pageSize * 2 {
                models.retainOldest(pageSize)
            } else {
                models.retainOldest(trimCount)
            }
            layoutIfNeeded()
        }
    }

    func reloadScrollView(for _: ChatScrollCoordinator) {
        layoutIfNeeded()
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

    func resetDatasourceIfNeeded() {
        if scrollController.updateState(is: .notUpdating), !canLoadNewerMessages,
           models.count > conversationConfig.pageSize + 5 {
            scrollController.send(.scrollTo(.edge(.bottom), enqueue: false))
            models.retainNewest(conversationConfig.pageSize)
            layoutIfNeeded()
        }
    }

    func resetDatasource() {
        scrollController.begin(updates: .reset)
        Task {
            do {
                let msgs = try await messageSource.reset(conID: conversationConfig.conID)
                await reloadData(with: msgs, forceReset: true)
            } catch {
                await self.showError(error)
            }
        }
    }
}
