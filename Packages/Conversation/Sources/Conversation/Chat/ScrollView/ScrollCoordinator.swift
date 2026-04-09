// © 2026 Aung Ko Min

import Core
import Database
import ImageLoader
import OSLog
import Services
import SwiftUI
import XUI

// MARK: - ScrollCoordinator

@MainActor
@Observable
final class ScrollCoordinator: ErrorPresenter {
    // MARK: Lifecycle

    init() {
        let initial = State(
            updateState: .initial,
            geometry: .empty,
            phase: .idle,
            isFirstResponder: false,
            scrolledPosition: .none,
        )

        state = initial
        ignoredState = initial

        displayLink.onTargetReached = { [weak self] _ in
            guard let self else {
                return
            }

            if pendingScrollRequests.isEmpty {
                finalizeScrollUpdates()
            } else {
                scrollIfNeeded()
            }
        }
    }

    // MARK: Internal

    @ObservationIgnored weak var delegate: ScrollCoordinatorDelegate?
    @ObservationIgnored private(set) var state: State
    @ObservationIgnored private(set) var ignoredState: State

    var scrollPositionBindable: Binding<ScrollPosition> {
        .init(
            get: {
                self.scrollPosition
            },
            set: { _ in self.scrollPosition = .init(idType: String.self) },
        )
    }

    // MARK: Private

    private var scrollPosition: ScrollPosition = .init(idType: String.self)

    @ObservationIgnored private var pendingScrollRequests: Deque<ScrollPositionItem> = .init()
    @ObservationIgnored private let reducer: ScrollReducer = .init()
    @ObservationIgnored private let displayLink: DisplayLink = .init(0.3)
}

extension ScrollCoordinator {
    func isNear(_ edge: VerticalEdge) -> Bool {
        ignoredState.geometry.isNear(edge)
    }

    func updateStateUpdate(to value: ScrollViewUpdate) {
        ignoredState.updateState.update(to: value)
    }

    func updatedState(is value: ScrollViewUpdate) -> Bool {
        ignoredState.updateState == value
    }
}

extension ScrollCoordinator {
    func send(_ intent: Intent) {
        func shouldPaginate(_ edge: VerticalEdge) -> Bool {
            delegate?.scrollCoordinator(self, shouldPaginateAt: edge) == true
        }

        let shouldAdjustWindow = delegate?.scrollCoordinatorShouldRemove(self) == true

        guard prepare(intent) else {
            return
        }

        let effect = reducer.reduce(
            state: ignoredState,
            intent: intent,
            canLoadOlder: shouldPaginate(.top),
            canLoadNewer: shouldPaginate(.bottom),
            shouldAdjustWindow: shouldAdjustWindow,
        )

        handleEffect(effect)
    }

    private func prepare(_ intent: Intent) -> Bool {
        switch intent {
        case let .onBottomBarFrameChage(old, new):
            guard ignoredState.updateState.hasViewLoaded else {
                return false
            }

            if new.height == old.height, new.maxY != old.maxY {
                ignoredState.isFirstResponder = new.maxY < old.maxY
            }
            guard ignoredState.scrolledPosition != .atBottom else {
                delegate?.layoutIfNeeded()
                return false
            }

            if ignoredState.isFirstResponder {
                let diff = old.maxY - new.maxY
                let y = min(
                    ignoredState.geometry.bottomMostOffset,
                    ignoredState.geometry.offsetY + diff,
                )
                performScroll(to: .y(y, properties: .notAnimated))
            }
            return false

        case let .onScrollGeometryChange(_, new):
            ignoredState.geometry = new
            guard ignoredState.updateState.hasViewLoaded else {
                if new.scrolledPosition == .atBottom {
                    ignoredState.updateState.setHasViewLoaded()
                    state = ignoredState
                } else {
                    scrollPosition = .init(idType: String.self, edge: .bottom)
                }
                return false
            }

            if new.offsetY < ChatLayoutConstants.paginationTrashold {
                return true
            }
            if new.offsetY > new.contentHeight - new.boundsHeight {
                return true
            }
            return ignoredState.updateState.isUpdating

        case let .onScrollPhaseChange(old, new, _):
            ignoredState.scrolledPosition = ignoredState.geometry.scrolledPosition
            guard ignoredState.updateState.hasViewLoaded else {
                return false
            }

            ignoredState.phase = new
            guard ignoredState.updateState.isNotUpdating else {
                return false
            }

            switch new {
            case .idle:
                if old == .interacting, ignoredState.isFirstResponder {
                    UIApplication.shared.endEditing()
                } else {
                    queueToFinalizeUpdates()
                }
            case .interacting:
                scrollPosition = .init()
                displayLink.stop()
                pendingScrollRequests.removeAll()
            default:
                displayLink.stop()
            }
            return false
        }
    }

    private func handleEffect(_ effect: ScrollReducer.Effect) {
        switch effect {
        case let .begingUpdate(updates):
            begin(updates: updates)
        case let .endUpdate(updates, item):
            if let item {
                performScroll(to: item)
            }
            end(updates: updates)
        case .noAction:
            break
        }
    }

    private func begin(updates: DataUpdate) {
        pendingScrollRequests.removeAll()
        ignoredState.updateState.update(to: .willBeginUpdates)
        switch updates {
        case let .insert(edge):
            delegate?.scrollCoordinator(self, paginateAt: edge)
        case let .remove(edge):
            delegate?.scrollCoordinator(self, removeAt: edge)
        case let .append(id):
            ignoredState.updateState.update(to: .appendingItem(id))
        }
    }

    private func end(updates _: DataUpdate) {
        ignoredState.updateState.update(to: .didEndUpdates)
    }

    private func finalizeScrollUpdates() {
        scrollPosition.isPositionedByUser = true
        if ignoredState.updateState.hasViewLoaded {
            delegate?.scrollCoordinator(self, finalizeUpdate: state, newState: ignoredState)
        }
        state = ignoredState
    }

    private func queueToFinalizeUpdates() {
        displayLink.start()
    }
}

extension ScrollCoordinator {
    func enqueueScroll(to value: ScrollPositionItem) {
        pendingScrollRequests.enqueue(value)
        queueToFinalizeUpdates()
    }

    private func scrollIfNeeded() {
        guard let value = pendingScrollRequests.dequeue() else {
            return
        }

        performScroll(to: value)
    }

    func orientationDidChange() {
        if ignoredState.scrolledPosition == .atBottom {
            scrollPosition = .init(idType: String.self, edge: .bottom)
        }
    }

    func performScroll(to newValue: ScrollPositionItem) {
        switch newValue.properties {
        case let .animated(animation):
            if ignoredState.phase.isScrolling {
                enqueueScroll(to: newValue)
                return
            }
            let transaction = Transaction.withAnimation(animation)
            withTransaction(transaction) {
                scroll(to: newValue.position)
            }
        case .notAnimated:
            let transaction = Transaction.withoutAnimation()
            withTransaction(transaction) {
                scroll(to: newValue.position)
            }
        case .scroll:
            let transaction = Transaction.scrollView()
            withTransaction(transaction) {
                scroll(to: newValue.position)
            }
        case .none:
            scroll(to: newValue.position)
        }
    }

    private func scroll(to newValue: ScrollPositionValue) {
        switch newValue {
        case let .y(value):
            scrollPosition.scrollTo(y: value)
        case let .id(value, anchor):
            scrollPosition.scrollTo(id: value, anchor: anchor)
        case let .edge(edge):
            scrollPosition.scrollTo(edge: edge)
        case let .nearBottom(space):
            let geometry = ignoredState.geometry
            scrollPosition
                .scrollTo(y: max(0, min(geometry.bottomMostOffset - space, geometry.offsetY)))
        }
    }
}
