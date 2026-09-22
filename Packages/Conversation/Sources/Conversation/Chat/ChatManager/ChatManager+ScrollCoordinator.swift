//  ChatManager+ScrollCoordinator.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database
import Services
import SwiftUI
import XUI

// MARK: - ScrollCoordinatorDelegate

extension ChatManager: @preconcurrency ScrollCoordinatorDelegate {

    var isFirstResponder: Bool {
        focusState?.value != nil
    }

    func scrollCoordinator(_ coordinator: ScrollCoordinator, setEditing isEditing: Bool) -> Bool {
        if isEditing {
            return beginEditing(coordinator)
        }
        if !isEditing {
            return endEditing()
        }
        return false
    }

    private func beginEditing(_ coordinator: ScrollCoordinator) -> Bool {
        guard focusState?.value == nil else { return false }
        guard !messages.shouldPaginate(at: .bottom) else { return false }

        UIImpactFeedbackGenerator().impactOccurred(intensity: 0.7)
        coordinator.performScroll(to: .edge(.bottom, .notAnimated))
        focusState?.value = .inputTextField
        return true
    }

    private func endEditing() -> Bool {
        guard focusState?.value != nil else { return false }
        focusState?.value = nil
        return true
    }

    func paginatableState() -> PaginatableState {
        messages.paginatableState()
    }

    func scrollCoordinator(_ coordinator: ScrollCoordinator, begin update: ScrollCoordinator.DataUpdate) {
        guard coordinator.updateState == .willBeginUpdates else { return }

        switch update {
        case .insert(let edge):
            handleInsert(edge: edge, update: update, coordinator: coordinator)

        case .remove(let edge):
            handleRemove(edge: edge, update: update, coordinator: coordinator)

        case .focus(let message):
            handleFocus(message: message)
        }
    }

    func scrollCoordinator(
        _ coordinator: ScrollCoordinator, finalizeScrollViewUpdatesWith state: ScrollCoordinator.State
    ) {
        let accessoryItem: AccessoryBarItem? = messages.isAbsoluteScrolled(at: .bottom) ? nil : .scrollDownButton

        if accessoryItem == nil {
            presentation.send(.date(nil))
        } else if let dateString = messages.firstVisibleDateString() {
            presentation.send(.date(dateString))
        }

        guard accessoryItem != presentation.state.bottomAccessory else { return }
        presentation.send(.bottomAccessory(accessoryItem))

        if accessoryItem == nil, messages.shouldAdjustWindow {
            messages.retainNewest(messages.pagination.pageSize * 2)
            layoutIfNeeded()
        }
    }

    func onScrollTargetVisibilityChange(_ newValue: [String]) {
        messages.onScrollTargetVisibilityChange(newValue)
    }
}

// MARK: - Insert Handling

extension ChatManager {

    private func handleInsert(
        edge: VerticalEdge,
        update: ScrollCoordinator.DataUpdate,
        coordinator: ScrollCoordinator
    ) {
        switch edge {
        case .top:
            insertPreviousMessages(update: update, coordinator: coordinator)
        case .bottom:
            insertNextMessages(update: update, coordinator: coordinator)
        }
    }

    private func insertPreviousMessages(update: ScrollCoordinator.DataUpdate, coordinator: ScrollCoordinator) {
        Task {
            guard let message = messages.first?.msg else {
                coordinator.updateState(.didEndUpdates)
                return
            }
            do {
                let previousMessages = try await datasource.previous(before: message.date, conID: message.conID)
                messages.prepend(previousMessages)
                coordinator.updateState(.dataUpdate(update))
                layoutIfNeeded()
            } catch {
                log(error)
            }
        }
    }

    private func insertNextMessages(update: ScrollCoordinator.DataUpdate, coordinator: ScrollCoordinator) {
        Task {
            guard let message = messages.last?.msg else {
                coordinator.updateState(.didEndUpdates)
                return
            }
            do {
                let nextMessages = try await datasource.more(after: message.date, conID: message.conID)
                messages.append(nextMessages)
                coordinator.updateState(.dataUpdate(update))
                layoutIfNeeded()
            } catch {
                log(error)
            }
        }
    }
}

// MARK: - Remove Handling

extension ChatManager {

    private func handleRemove(
        edge: VerticalEdge,
        update: ScrollCoordinator.DataUpdate,
        coordinator: ScrollCoordinator
    ) {
        let limit = messages.pagination.pageSize * 3
        switch edge {
        case .top:
            messages.retainNewest(limit)
        case .bottom:
            messages.retainOldest(limit)
        }
        coordinator.updateState(.dataUpdate(update))
        layoutIfNeeded()
    }
}

// MARK: - Focus Handling

extension ChatManager {

    private func handleFocus(message: Message) {
        Task {
            try? await scrollTo(msg: message)
        }
    }

    func scrollTo(msg: Message) async throws {
        scrollController.updateState(.willBeginUpdates)
        let messages = try await datasource.msg(from: msg.date, conID: msg.conID)
        self.messages.set(msgs: messages)
        scrollController.updateState(.dataUpdate(.focus(msg: msg)))
        layoutIfNeeded()
    }
}
