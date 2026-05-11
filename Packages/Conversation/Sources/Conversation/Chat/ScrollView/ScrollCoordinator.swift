//  ScrollCoordinator.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import Database
import ImageLoader
import OSLog
import Services
import SwiftUI
import XUI

@MainActor @Observable final class ScrollCoordinator {
    weak var delegate: ScrollCoordinatorDelegate?
    @ObservationIgnored
    private let reducer: ScrollReducer = .init()
    @ObservationIgnored
    private let debouncer: Debouncer = .init(delay: 0.3)
    @ObservationIgnored
    private var state: State = .init()
    private var scrollPosition: ScrollPosition = .init()
    @ObservationIgnored
    var scrollPositionBindable: Binding<ScrollPosition> {
        .init(get: { self.scrollPosition }, set: { _ in })
    }
}

extension ScrollCoordinator {
    func updateStateUpdate(to value: ScrollViewUpdate) {
        state.updateState.update(to: value)
    }
}

extension ScrollCoordinator {
    func send(_ intent: Intent) {
        switch intent {
        case .onScrollGeometryChange(let oldValue, let newValue):
            let state = state
            guard state.updateState.hasViewLoaded else {
                handleHasViewLoaded(newValue)
                return
            }
            guard oldValue.boundsSize == newValue.boundsSize else {
                onScrollViewSizeChange(oldValue, newValue)
                return
            }
            if state.updateState.isUpdating {
                guard state.updateState.canReduceUpdates else { return }
                if let effect = reducer.handleUpdating(
                    state: state.updateState,
                    oldValue: oldValue,
                    newValue: newValue
                ) {
                    handleEffect(effect)
                }
            } else {
                if state.isFirstResponder {
                    handleFirstResponder(oldValue, newValue)
                }
            }
        case .onScrollPhaseChange(let oldValue, let newValue, let context):
            let geometry = VScrollGeometry(context.geometry)
            var state = self.state
            state.phase = newValue
            switch newValue {
            case .idle:
                debouncer.debounce { [weak self] in
                    guard let self else { return }
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.finalizeScrollUpdates()
                    }
                }
                if oldValue != .interacting {
                    paginateIfNeeded(geometry, state: state)
                }
                state.scrollDirection = .none
            case .interacting:
                if oldValue == .decelerating {
                    paginateIfNeeded(geometry, state: state)
                }
            case .decelerating:
                let velocity = context.velocity?.dy ?? 0
                if velocity != 0 {
                    let scrollDirection: ScrollDirection =
                        velocity <= 0 ? .down : .up
                    state.scrollDirection = scrollDirection
                }
                if oldValue == .interacting {
                    paginateIfNeeded(geometry, state: state)
                }
            default:
                break
            }
            self.state = state
        case .begin(let update):
            begin(updates: update)
        }
    }

    private func paginateIfNeeded(_ geometry: VScrollGeometry, state: State) {
        if state.updateState.isNotUpdating {
            if let effect = reducer.reduceGeometry(
                newValue: geometry,
                paginationState: paginatedState(),
                phase: state.phase
            ) {
                handleEffect(effect)
            }
        }
    }
    private func paginatedState() -> PaginationState {
        func shouldPaginate(_ edge: VerticalEdge) -> Bool {
            delegate?.scrollCoordinator(self, shouldPaginateAt: edge) == true
        }
        let shouldAdjustWindow =
            delegate?.scrollCoordinatorShouldRemove(self) == true
        let newValue = PaginationState(
            canLoadOlder: shouldPaginate(.top),
            canLoadNewer: shouldPaginate(.bottom),
            canAdjustSize: shouldAdjustWindow
        )
        return newValue
    }
}

extension ScrollCoordinator {
    private func handleHasViewLoaded(_ geometry: VScrollGeometry) {
        scrollPosition.scrollTo(y: geometry.bottomMostOffset)
        state.updateState.setHasViewLoaded()
    }

    private func handleFirstResponder(
        _ oldValue: VScrollGeometry,
        _ newValue: VScrollGeometry
    ) {
        if state.phase == .interacting {
            if newValue.offsetY < oldValue.offsetY {
                if oldValue.offsetY - newValue.offsetY > 20 {
                    UIApplication.shared.endEditing()
                }
            }
        }
    }

    private func onScrollViewSizeChange(
        _ oldValue: VScrollGeometry,
        _ newValue: VScrollGeometry
    ) {
        delegate?.layoutIfNeeded()
        guard oldValue.boundsSize.height != newValue.boundsSize.height else {
            return
        }
        let isFirstResponder = newValue.boundsHeight < oldValue.boundsHeight
        guard state.isFirstResponder != isFirstResponder else { return }
        state.isFirstResponder = isFirstResponder
        finalizeScrollUpdates()
        let diff = oldValue.boundsHeight - newValue.boundsHeight
        if oldValue.scrolledPosition != .atBottom {
            let y = newValue.offsetY + diff
            scrollPosition.scrollTo(y: y)
        }
    }

    private func handleEffect(_ effect: ScrollReducer.Effect) {
        switch effect {
        case .begingUpdate(let updates): begin(updates: updates)
        case .endUpdate(let updates, let item):
            if let item { performScroll(to: item) }
            Task.detached { [weak self] in
                guard let self else { return }
                await end(updates: updates)
            }
        }
    }

    private func begin(updates: DataUpdate) {
        delegate?.scrollCoordinator(self, begin: updates)
    }

    private func end(updates: DataUpdate) {
        switch updates {
        case .insert(let edge, let geometry):
            switch edge {
            case .top:
                if state.phase.isScrolling {
                    begin(updates: .remove(edge: .bottom, geometry: geometry))
                } else {
                    state.updateState.update(to: .didEndUpdates)
                }
            case .bottom:
                state.updateState.update(to: .didEndUpdates)
            }
        case .remove(let edge, _):
            switch edge {
            case .top: state.updateState.update(to: .didEndUpdates)
            case .bottom:
                state.updateState.update(to: .didEndUpdates)
            }
        case .append: state.updateState.update(to: .didEndUpdates)
        case .resetting(let msg):
            state.updateState.update(to: .didEndUpdates)
            Task.detached { [weak self] in
                guard let self else { return }
                await performScroll(to: .id(msg.uid, anchor: .bottom, .animated()))
            }
        }
    }

    private func finalizeScrollUpdates() {
        delegate?.scrollCoordinator(self, finalizeScrollViewUpdatesWith: state)
    }
}

extension ScrollCoordinator {
    func performScroll(to newValue: ScrollPositionItem) {

        switch newValue.properties {
        case .animated(let animation):
            withTransaction(
                .withAnimation(animation) { [weak self] in
                    guard let self else { return }
                    scrollPosition = .init()
                }
            ) { scroll(to: newValue.position) }
        case .notAnimated:
            withTransaction(
                .withoutAnimation { [weak self] in
                    guard let self else { return }
                    scrollPosition = .init()
                }
            ) { scroll(to: newValue.position) }
        case .scroll:
            if state.phase.isScrolling {
                withTransaction(
                    .scrollView { [weak self] in
                        guard let self else { return }
                        scrollPosition = .init()
                    }
                ) { scroll(to: newValue.position) }
            } else {
                withTransaction(
                    .withoutAnimation { [weak self] in
                        guard let self else { return }
                        scrollPosition = .init()
                    }
                ) { scroll(to: newValue.position) }
            }
        }
    }

    private func scroll(to newValue: ScrollPositionValue) {
        switch newValue {
        case .y(let value):
            scrollPosition.scrollTo(y: value)
        case .id(let value, let anchor):
            scrollPosition.scrollTo(id: value, anchor: anchor)
        case .edge(let edge):
            switch edge {
            case .top:
                scrollPosition.scrollTo(y: 0)
            case .bottom:
                scrollPosition.scrollTo(edge: .bottom)
            default: break
            }
        }
    }
}
