//  ChatManager+ScrollCoordinator.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI
import Database
import Services

extension ChatManager: @preconcurrency ScrollCoordinatorDelegate {
    var isFirstResponder: Bool {
        focusState?.value != nil
    }
    
    
    func scrollCoordinator(_ coordinator: ScrollCoordinator, setEditing isEditing: Bool) -> Bool {
        if isEditing && focusState?.value == nil && messages.shouldPaginate(at: .bottom) == false {
            UIImpactFeedbackGenerator().impactOccurred(intensity: 0.7)
            coordinator.performScroll(to: .edge(.bottom, .notAnimated))
            focusState?.value = .inputTextField
            return true
        } else if !isEditing && focusState?.value != nil {
            focusState?.value =  nil
            return true
        }
        return false
    }

    func getPaginationState() -> PaginatableState? {
        messages.paginatableState
    }

    func scrollCoordinator(
        _ coordinator: ScrollCoordinator, begin update: ScrollCoordinator.DataUpdate
    ) {
        switch update {
        case let .insert(edge):
            switch edge {
            case .top:
                let message = messages.first?.msg
                guard let message else {
                    scrollController.updateState(.didEndUpdates)
                    return
                }
                let query = message.date
                serialQueue.async { [weak self] in
                    guard let self else { return }
                    do {
                        let msgs = try await datasource.previous(before: query, conID: message.conID )
                        await messages.prepend(msgs)
                        await coordinator.updateState(.dataUpdate(update) )
//                        await layoutIfNeeded()
                    } catch {
                        log(error)
                    }
                }
            case .bottom:
                
                let message = messages.last?.msg
                guard let message else {
                    scrollController.updateState(.didEndUpdates)
                    return
                }
                let query = message.date
                serialQueue.async { [weak self] in
                    guard let self else { return }
                    do {
                        let msgs = try await datasource.previous(before: query, conID: message.conID )
                        await messages.append(msgs)
                        await coordinator.updateState(.dataUpdate(update) )
//                        await layoutIfNeeded()
                    } catch {
                        log(error)
                    }
                }
            }
        case let .remove(edge):
            let limit = messages.pagination.pageSize * 2
            switch edge {
            case .top:
                messages.retainNewest(limit)
                coordinator.updateState(.dataUpdate(update))
                layoutIfNeeded()
            case .bottom:
                messages.retainOldest(limit)
                coordinator.updateState(.dataUpdate(update))
                withAnimation(.linear) { layoutIfNeeded() }
            }
        case let .append(msg):
            serialQueue.async { [weak self] in
                guard let self else { return }
                await coordinator.updateState(.dataUpdate(.append(msg: msg)))
                await messages.insert(msg: msg)
                await layoutIfNeeded()
            }
        case let .focus(msg):
            serialQueue.async { [weak self] in
                guard let self else { return }
                try? await scrollTo(msg: msg)
            }
        }

    }

    func scrollCoordinator(
        _: ScrollCoordinator, finalizeScrollViewUpdatesWith state: ScrollCoordinator.State
    ) {
        let item: AccessoryBarItem? = messages.isAbsoluteScrolled(at: .bottom) ? nil : .scrollDownButton
        if item == nil {
            presentation.send(.date(nil))
        } else {
            if let dateString = messages.firstVisibleDateString() {
                presentation.send(.date(dateString))
            }
        }
        guard item != presentation.state.bottomAccessory else { return }
        presentation.send(.bottomAccessory(item))
        if item == nil, messages.shouldAdjustWindow {
            messages.retainNewest(messages.pagination.pageSize)
            layoutIfNeeded()
        }
    }

    func onScrollTargetVisibilityChange(_ newValue: [String]) {
        messages.onScrollTargetVisibilityChange(newValue)
    }
}

extension ChatManager {
    func scrollTo(msg: Message) async throws {
        scrollController.updateState(.willBeginUpdates)
        let query = msg.date
        let msgs = try await datasource.msg(from: query, conID: msg.conID)
        messages.set(msgs: msgs)
        scrollController.updateState(.dataUpdate(.focus(msg: msg)))
        layoutIfNeeded()
    }
}
