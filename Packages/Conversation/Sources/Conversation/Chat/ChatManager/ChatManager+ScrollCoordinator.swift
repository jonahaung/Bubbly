//  ChatManager+ScrollCoordinator.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI
import Database
import Services

extension ChatManager: @preconcurrency ScrollCoordinatorDelegate {
    func scrollCoordinator(
        _ coordinator: ScrollCoordinator, begin update: ScrollCoordinator.DataUpdate
    ) {
        serialQueue.addOperation { [weak self] in
            guard let self else { return }
            switch update {
            case let .insert(edge, _):
                switch edge {
                case .top:
                    let message = models.first?.msg
                    guard let message else {
                        scrollController.updateStateUpdate(to: .didEndUpdates)
                        return
                    }
                    let query = message.date
                    let msgs = try await datasource.previous(before: query, conID: message.conID )
                    models.prepend(msgs)
                    coordinator.updateStateUpdate(to: .dataUpdate(update) )
                    layoutIfNeeded()
                case .bottom:
                    let message = models.last?.msg
                    guard let message else {
                        scrollController.updateStateUpdate(to: .didEndUpdates)
                        return
                    }
                    let query = message.date
                    let msgs = try await datasource.more(after: query, conID: message.conID )
                    models.append(msgs)
                    coordinator.updateStateUpdate(to: .dataUpdate(update) )
                    layoutIfNeeded()
                }
            case let .remove(edge, _):
                let limit = models.pagination.pageSize * 2
                switch edge {
                case .top:
                    models.retainNewest(limit)
                    coordinator.updateStateUpdate(to: .dataUpdate(update))
                    layoutIfNeeded()
                case .bottom:
                    models.retainOldest(limit)
                    coordinator.updateStateUpdate(to: .dataUpdate(update))
                    withAnimation { layoutIfNeeded() }
                }
            case let .append(msg):
                models.insert(msg: msg)
                coordinator.updateStateUpdate(to: .dataUpdate(.append(msg: msg)))
                layoutIfNeeded()
                coordinator.performScroll(to: .id(msg.uid, anchor: .bottom, .animated(.interactiveSpring)))
            case let .resetting(msg):
                try await scrollTo(msg: msg)
            }
        }
    }
    
    func scrollCoordinator(_: ScrollCoordinator, shouldPaginateAt edge: VerticalEdge ) -> Bool {
        models.shouldPaginate(at: edge)
    }

    func scrollCoordinatorShouldRemove(_: ScrollCoordinator) -> Bool {
        models.shouldAdjustSize
    }

    func scrollCoordinator(
        _: ScrollCoordinator, finalizeScrollViewUpdatesWith state: ScrollCoordinator.State
    ) {
        let item: AccessoryBarItem? = models.isAbsoluteScrolled(at: .bottom) ? nil : .scrollDownButton
        presentation.send(.bottomAccessory(item))
        if let dateString = models.firstVisibleDateString() {
            presentation.send(.date(dateString))
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
        scrollController.updateStateUpdate(to: .dataUpdate(.resetting(msg: msg)))
        layoutIfNeeded()
    }
}
