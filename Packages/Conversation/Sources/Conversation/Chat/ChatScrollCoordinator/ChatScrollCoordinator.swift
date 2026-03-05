//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import ImageLoader
import OSLog
import Services
import SwiftUI
import XUI

@MainActor
@Observable
final class ChatScrollCoordinator: ErrorPresenter {

    @ObservationIgnored private var pendingScrollRequests = Deque<ScrollPositionItem>()
    @ObservationIgnored weak var delegate: ChatScrollCoordinatorDelegate?
    @ObservationIgnored private let reducer = ScrollReducer()
    @ObservationIgnored private let displayLink = DisplayLink(0.5)

    private var scrollPosition = ScrollPosition()
    private(set) var state: State
    @ObservationIgnored private var ignoredState: State

    init() {
        let initialState = State(
            updateState: .initial,
            geometry: .empty,
            direction: .down,
            phase: .idle,
            isFirstResponder: false,
            visibleIDs: []
        )
        state = initialState
        ignoredState = initialState
        displayLink.onTargetReached = { [weak self] _ in
            guard let self else { return }
            if ignoredState.phase.isScrolling {
                displayLink.start()
            } else {
                if pendingScrollRequests.isEmpty {
                    finalizeScrollUpdates()
                } else {
                    scrollIfNeeded()
                }
            }
        }
    }
}

extension ChatScrollCoordinator {
    func isNear(_ edge: VerticalEdge) -> Bool {
        ignoredState.geometry.isNear(edge)
    }

    func updateStateUpdate(to newValue: ScrollViewUpdate) {
        ignoredState.updateState.update(to: newValue)
    }

    func updateState(is state: ScrollViewUpdate) -> Bool {
        ignoredState.updateState == state
    }
}

extension ChatScrollCoordinator {
    var scrollPositionBindable: Binding<ScrollPosition> {
        .init(
            get: { [weak self] in
                guard let self else { return .init() }
                return self.scrollPosition
            }
        ) { [weak self] newValue in
            guard let self else { return }
            if newValue.isPositionedByUser {
            } else {
                self.scrollPosition = .init()
            }
        }
    }

    private var canLoadOlderMessages: Bool {
        delegate?
            .scrollCoordinator(
                self,
                shouldPaginateAt: .top
            ) == true && ignoredState.updateState.isNotUpdating
    }

    private var canLoadNewerMessages: Bool {
        delegate?
            .scrollCoordinator(self, shouldPaginateAt: .bottom) == true
            && ignoredState.updateState.isNotUpdating
    }

    private var shouldAdjustWindow: Bool {
        delegate?.scrollCoordinatorShouldRemove(self) == true
    }

    func loadOlderMessagesIfNeeded() {
        delegate?.scrollCoordinator(self, paginateAt: .top)
    }

    private func loadNewerMessagesIfNeeded() {
        delegate?.scrollCoordinator(self, paginateAt: .bottom)
    }

    private func onScrollDirectionChanged(_ newValue: VerticalDirection) {
        pendingScrollRequests.removeAll()
    }
}

extension ChatScrollCoordinator {

    func send(_ intent: Intent) {
        if prepare(intent) {
            let effect = reducer.reduce(
                state: &ignoredState,
                intent: intent,
                canLoadOlder: canLoadOlderMessages,
                canLoadNewer: canLoadNewerMessages,
                shouldAdjustWindow: shouldAdjustWindow
            )

            handle(effect)
        }
    }
}

extension ChatScrollCoordinator {
    private func prepare(_ intent: Intent) -> Bool {
        switch intent {
        case let .onVisibilityChange(visibility):
            switch visibility {
            case .automatic:
                break
            case .visible:
                ignoredState.updateState.setHasViewLoaded()
                finalizeScrollUpdates()
            case .hidden:
                break
            }
            return false
        case let .onBottomBarFrameChage(oldValue, newValue):
            guard ignoredState.updateState.hasViewLoaded else { return false }
            if newValue.height == oldValue.height && newValue.maxY != oldValue.maxY {
                ignoredState.isFirstResponder = newValue.maxY < oldValue.maxY
            }
            guard ignoredState.updateState.isNotUpdating else { return false }
            guard newValue.maxY < oldValue.maxY else { return false }
            guard ignoredState.geometry.scrolledPosition != .atBottom else { return false }
            let targetY = ignoredState.geometry.offsetY + oldValue.maxY - newValue.maxY
            if ignoredState.phase.isScrolling {
                enqueueScroll(to: .y(targetY, animation: .interactiveSpring(duration: 0.2)))
            } else {
                scrollPosition.scrollTo(y: targetY)
            }
            return false
        case let .onScrollGeometryChange(oldValue, newValue):
            ignoredState.geometry = newValue
            guard ignoredState.updateState.hasViewLoaded else { return false }
            let direction: VerticalDirection = newValue.offsetY < oldValue.offsetY ? .up : .down
            if ignoredState.direction != direction {
                ignoredState.direction = direction
                onScrollDirectionChanged(direction)
            }
            return true
        case let .onScrollPhaseChange(oldValue, newValue, context):
            guard oldValue != newValue else { return false }
            ignoredState.phase = newValue
            switch newValue {
            case .idle:
                ignoredState.geometry = .init(context.geometry)
                displayLink.start()
            case .tracking:
                break
            case .interacting:
                pendingScrollRequests.removeAll()
            case .decelerating:
                if oldValue == .interacting,
                   ignoredState.direction == .up && ignoredState.isFirstResponder {
                    Task { @MainActor in
                        UIApplication.shared.endEditing()
                    }
                }
            case .animating:
                break
            }
            return false
        case let .onScrollTargetVisibilityChange(newValue):
            ignoredState.visibleIDs = newValue
            return false
        case .onScrollTargetChange:
            return true
        case let .scrollTo(item, enqueue):
            if enqueue {
                enqueueScroll(to: item)
            } else {
                performScroll(to: item)
            }
            return false
        }
    }

    private func handle(_ effect: ScrollReducer.Effect) {
        switch effect {
        case let .scroll(item):
            performScroll(to: item)
        case let .begingUpdate(updates):
            begin(updates: updates)
        case let .endUpdate(updates, item):
            end(updates: updates)
            if let item {
                performScroll(to: item)
            }
        case .finalizeScrollViewUpdates:
            displayLink.start()
        case .removePendingUpdates:
            pendingScrollRequests.removeAll()
        case .noAction:
            break
        }
    }

    func begin(updates: DataUpdate) {
        displayLink.stop()

        switch updates {
        case let .insert(edge):
            ignoredState.updateState.update(to: .insertingItems(edge))
            switch edge {
            case .top:
                loadOlderMessagesIfNeeded()
            case .bottom:
                loadNewerMessagesIfNeeded()
            }
        case let .remove(edge):
            ignoredState.updateState.update(to: .removingItems(edge))
            delegate?.scrollCoordinator(self, removeAt: edge)
        case .reset:
            ignoredState.updateState.update(to: .resetting)
        case let .append(id):
            ignoredState.updateState.update(to: .appendingItem(id))
        }
    }

    private func end(updates: DataUpdate) {
        switch updates {
        case let .insert(edge):
            switch edge {
            case .top:
                ignoredState.updateState.update(to: .notUpdating)
            case .bottom:
                ignoredState.updateState.update(to: .notUpdating)
            }
        case let .remove(edge):
            switch edge {
            case .top:
                ignoredState.updateState.update(to: .notUpdating)
            case .bottom:
                ignoredState.updateState.update(to: .insertingItems(.top))
                loadOlderMessagesIfNeeded()
            }
        case .reset:

            ignoredState.updateState.update(to: .notUpdating)
        case .append:
            ignoredState.updateState.update(to: .notUpdating)
        }
        displayLink.start()
    }

    private func finalizeScrollUpdates() {
        if ignoredState.updateState.isUpdating {
            ignoredState.updateState.update(to: .notUpdating)
        }
        ignoredState.updateState.update(to: .notUpdating)
        delegate?.scrollCoordinator(self, finalizeUpdate: state, newState: ignoredState)
        state = ignoredState
    }
}

extension ChatScrollCoordinator {
    private func enqueueScroll(to newValue: ScrollPositionItem) {
        let isEmpty = pendingScrollRequests.isEmpty
        pendingScrollRequests.enqueue(newValue)
        if isEmpty {
            Task { @MainActor [weak self] in
                guard let self else { return }
                await Task.yield()
                scrollIfNeeded()
            }
        }
    }

    private func scrollIfNeeded() {
        guard let newValue = pendingScrollRequests.dequeue() else {
            return
        }
        performScroll(to: newValue)
    }

    private func performScroll(to newValue: ScrollPositionItem) {

        if let animation = newValue.animation {
            let transaction = Transaction.withAnimation(animation) { [weak self] in
                guard let self else { return }
                displayLink.start()
            }
            withTransaction(transaction) {
                scroll(to: newValue)
            }
        } else {
            let transaction = Transaction.scrollView(preservePosition: false) { [weak self] in
                guard let self else { return }
                displayLink.start()
            }
            withTransaction(transaction) {
                scroll(to: newValue)
            }
        }
    }

    private func scroll(to newValue: ScrollPositionItem) {
        switch newValue.position {
        case let .y(value):
            ignoredState.geometry.offsetY = value
            scrollPosition = .init(y: value)
        case let .id(value):
            scrollPosition = .init(id: value)
        case let .layoutID(value):
            scrollPosition = .init(id: value)
        case let .edge(edge):
            scrollPosition = .init(edge: edge)
        case .snapToBottom:
            let geometry = ignoredState.geometry
            let offsetY = geometry.bottomMostOffset
            let adjustedY = max(0, (offsetY - 100))
            scrollPosition = .init(y: adjustedY)
            Task { @MainActor in
                await Task.yield()
                enqueueScroll(to: .edge(.bottom, animation: .default))
            }
        case let .snapToY(y):
            let adjustedY = max(0, (y - 100))
            scrollPosition = .init(y: adjustedY)
            Task { @MainActor in
                await Task.yield()
                enqueueScroll(to: .y(y, animation: .default))
            }
        }
    }
}
