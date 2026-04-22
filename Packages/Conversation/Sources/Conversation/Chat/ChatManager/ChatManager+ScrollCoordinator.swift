// © 2026 Aung Ko Min
import Database
import Services
import SwiftUI
import XUI
// MARK: - ChatManager + ScrollCoordinatorDelegate
extension ChatManager: ScrollCoordinatorDelegate {
    func scrollCoordinator(
        _ coordinator: ScrollCoordinator, begin update: ScrollCoordinator.DataUpdate
    ) {
        serialQueue.addOperation { [weak self] in
            guard let self else { return }
            switch update {
            case .insert(let edge, _):
                let message = edge == .top ? oldestMessage : newestMessage
                guard let message else {
                    scrollController.updateStateUpdate(to: .didEndUpdates)
                    return
                }
                let query = ServerTime(message.date).value
                let msgs =
                    switch edge {
                    case .top: try await datasource.previous(before: query, conID: message.conID, )
                    case .bottom: try await datasource.more(after: query, conID: message.conID, )
                    }
                if edge == .top {
                    models.prepend(msgs)
                    coordinator.updateStateUpdate(to: .dataUpdate(update), )
                    layoutIfNeeded()
                } else {
                    models.append(msgs)
                    coordinator.updateStateUpdate(to: .dataUpdate(update), )
                    withAnimation { layoutIfNeeded() }
                }
            case .remove(let edge, _):
                let limit = conversationConfig.pageSize * 2
                switch edge {
                case .top:
                    await models.retainNewest(limit)
                    coordinator.updateStateUpdate(to: .dataUpdate(update))
                    layoutIfNeeded()
                case .bottom:
                    await models.retainOldest(limit)
                    coordinator.updateStateUpdate(to: .dataUpdate(update))
                    withAnimation { layoutIfNeeded() }
                }
            case .append(_): break
            case .resetting(let msg): try await scrollTo(msg: msg)
            }
        }
    }
    func edgeMsg(at edge: VerticalEdge) -> Database.Message? {
        switch edge {
        case .top: models.first?.msg
        case .bottom: models.last?.msg
        }
    }
    private var isPaginatonEnabled: Bool { conversationConfig.canPaginate }
    func scrollCoordinator(_: ScrollCoordinator, shouldPaginateAt edge: VerticalEdge, ) -> Bool {
        guard isPaginatonEnabled else { return false }
        switch edge {
        case .top:
            guard let firstMsgID = conversationConfig.firstMsgID else { return false }
            return !models.contains(withID: firstMsgID)
        case .bottom:
            guard let lastMsgID = conversationConfig.lastMsgID else { return false }
            return !models.contains(withID: lastMsgID)
        }
    }
    func scrollCoordinatorShouldRemove(_: ScrollCoordinator) -> Bool {
        isPaginatonEnabled && models.count > conversationConfig.pageSize * 2
    }
    func scrollCoordinator(
        _: ScrollCoordinator, finalizeScrollViewUpdatesWith state: ScrollCoordinator.State,
    ) {
        let item: AccessoryBarItem? = {
            if state.scrolledPosition != .atBottom { return .scrollDownButton }
            if state.isFirstResponder { return .keyboardButton }
            return nil
        }()
        presentation.send(.bottomAccessory(item))
        if let dateString = models.getCurrentVisibleDateString() {
            presentation.send(.date(dateString))
        }
    }
    func scrollCoordinator(_: ScrollCoordinator, reset msg: Message) {
        serialQueue.addOperation { [weak self] in
            guard let self else { return }
            try await scrollTo(msg: msg)
        }
    }
    func onScrollTargetVisibilityChange(_ newValue: [String]) {
        models.onScrollTargetVisibilityChange(newValue)
    }
}
extension ChatManager {
    var newestMessage: Database.Message? { models.last?.msg }
    var oldestMessage: Database.Message? { models.first?.msg }
    func scrollTo(msg: Message) async throws {
        scrollController.updateStateUpdate(to: .willBeginUpdates)
        let query = ServerTime(msg.date).value
        let msgs = try await datasource.msg(from: query, conID: msg.conID)
        models.set(msgs: msgs)
        scrollController.updateStateUpdate(to: .dataUpdate(.resetting(msg: msg)))
        layoutIfNeeded()
    }
}
