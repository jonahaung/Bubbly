//  ChatManager+ScrollCoordinator.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI
import Database
import Services

extension ChatManager: @preconcurrency ScrollCoordinatorDelegate {
    
    func getPaginationState() -> PaginatableState? {
        models.paginatableState
    }
    
    func scrollCoordinator(
        _ coordinator: ScrollCoordinator, begin update: ScrollCoordinator.DataUpdate
    ) {
        guard coordinator.updateState == .willBeginUpdates else { return }
        switch update {
        case let .insert(edge):
            switch edge {
            case .top:
                let message = models.first?.msg
                guard let message else {
                    scrollController.updateStateUpdate(to: .didEndUpdates)
                    return
                }
                let query = message.date
                serialQueue.addOperation { [weak self] in
                    guard let self else { return }
                    let msgs = try await datasource.previous(before: query, conID: message.conID )
                    models.prepend(msgs)
                    coordinator.updateStateUpdate(to: .dataUpdate(update) )
                    layoutIfNeeded()
                }
            case .bottom:
                let message = models.last?.msg
                guard let message else {
                    scrollController.updateStateUpdate(to: .didEndUpdates)
                    return
                }
                let query = message.date
                serialQueue.addOperation { [weak self] in
                    guard let self else { return }
                    let msgs = try await datasource.more(after: query, conID: message.conID )
                    models.append(msgs)
                    coordinator.updateStateUpdate(to: .dataUpdate(update) )
                    layoutIfNeeded()
                }
            }
        case let .remove(edge):
            let limit = models.pagination.pageSize*2
            switch edge {
            case .top:
                models.retainNewest(limit)
                coordinator.updateStateUpdate(to: .dataUpdate(update))
                layoutIfNeeded()
            case .bottom:
                models.retainOldest(limit)
                coordinator.updateStateUpdate(to: .dataUpdate(update))
                withAnimation(.linear) { layoutIfNeeded() }
            }
        case let .append(msg):
            models.insert(msg: msg)
            coordinator.updateStateUpdate(to: .dataUpdate(.append(msg: msg)))
            layoutIfNeeded()
        case let .focus(msg):
            serialQueue.addOperation { [weak self] in
                guard let self else { return }
                try await scrollTo(msg: msg)
            }
        }

    }
    
    func scrollCoordinator(
        _: ScrollCoordinator, finalizeScrollViewUpdatesWith state: ScrollCoordinator.State
    ) {
        let item: AccessoryBarItem? = models.isAbsoluteScrolled(at: .bottom) ? nil : .scrollDownButton
        if item == nil {
            presentation.send(.date(nil))
        } else {
            if let dateString = models.firstVisibleDateString() {
                presentation.send(.date(dateString))
            }
        }
        guard item != presentation.state.bottomAccessory else { return }
        presentation.send(.bottomAccessory(item))
        if item == nil, models.shouldAdjustWindow {
            models.retainNewest(models.pagination.pageSize)
            layoutIfNeeded()
        }
    }
    
    func onScrollTargetVisibilityChange(_ newValue: [String]) {
        models.onScrollTargetVisibilityChange(newValue)
    }
}

extension ChatManager {
    func scrollTo(msg: Message) async throws {
        scrollController.updateStateUpdate(to: .willBeginUpdates)
        let query = msg.date
        let msgs = try await datasource.msg(from: query, conID: msg.conID)
        models.set(msgs: msgs)
        scrollController.updateStateUpdate(to: .dataUpdate(.focus(msg: msg)))
        layoutIfNeeded()
    }
}
