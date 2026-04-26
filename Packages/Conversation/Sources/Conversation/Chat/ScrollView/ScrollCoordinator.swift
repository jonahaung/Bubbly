//  ScrollCoordinator.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import OSLog
import SwiftUI
import Database
import Services
import ImageLoader

@MainActor @Observable final class ScrollCoordinator {
    weak var delegate: ScrollCoordinatorDelegate?
    private let reducer: ScrollReducer = .init()
    private let debouncer: Debouncer = .init(delay: 0.3)
    private var state: State = .init()
    private var scrollPosition: ScrollPosition = .init()
    var scrollPositionBindable: Binding<ScrollPosition> {
        .init(get: { self.scrollPosition }, set: { _ in })
    }
}

extension ScrollCoordinator {
    func isNear(_ edge: VerticalEdge) -> Bool { state.geometry.isNear(edge) }
    func updateStateUpdate(to value: ScrollViewUpdate) { state.updateState.update(to: value) }
}

extension ScrollCoordinator {
    func send(_ intent: Intent) {
        switch intent {
        case let .onScrollGeometryChange(oldValue, newValue):
            guard state.updateState.hasViewLoaded else {
                Task { @MainActor in
                    handleHasViewLoaded(newValue)
                }
                return
            }
            guard oldValue.boundsSize == newValue.boundsSize else {
                onScrollViewSizeChange(oldValue, newValue)
                return
            }
            let state = state
            if state.updateState.isUpdating {
                guard state.updateState.canReduceUpdates else { return }
                if let effect = reducer.handleUpdating(
                    state: state.updateState, oldValue: oldValue,
                    newValue: newValue
                ) {
                    handleEffect(effect)
                }
            } else {
                self.state.geometry = newValue
                if state.isFirstResponder {
                    handleFirstResponder(oldValue, newValue)
                }
                guard state.phase == .decelerating else { return }
                if let effect = reducer.reduceGeometry(
                    newValue: newValue, paginationState: getPaginationState(), scrollDirection: state.scrollDirection) {
                    handleEffect(effect)
                }
            }
        case let .onScrollPhaseChange(oldValue, newValue, context):
           
            guard oldValue != newValue else { return }
            state.phase = newValue
            
            switch newValue {
            case .idle:
                if state.updateState == .willEndUpdates {
                    state.updateState.update(to: .didEndUpdates)
                }
                debouncer.debounce { [weak self] in
                    guard let self else { return }
                    finalizeScrollUpdates()
                }
            case .interacting:
                if state.updateState == .willEndUpdates {
                    state.updateState.update(to: .didEndUpdates)
                }
            case .decelerating:
                let velocity = context.velocity?.dy ?? 0
                if velocity != 0 {
                    let scrollDirection: ScrollDirection = velocity == 0 ? .none : velocity < 0 ? .down : .up
                    state.scrollDirection = scrollDirection
                }
            default: break
            }
        case let .begin(update):
            begin(updates: update)
        }
    }

    private func getPaginationState() -> PaginationState {
        if let paginationState = state.paginationState { return paginationState }
        func shouldPaginate(_ edge: VerticalEdge) -> Bool {
            delegate?.scrollCoordinator(self, shouldPaginateAt: edge) == true
        }
        let shouldAdjustWindow = delegate?.scrollCoordinatorShouldRemove(self) == true
        let newValue = PaginationState(
            canLoadOlder: shouldPaginate(.top), canLoadNewer: shouldPaginate(.bottom),
            canAdjustSize: shouldAdjustWindow
        )
        state.paginationState = newValue
        return newValue
    }
}

extension ScrollCoordinator {
    private func handleHasViewLoaded(_ geometry: VScrollGeometry) {
        scrollPosition.scrollTo(y: geometry.bottomMostOffset)
        state.scrolledPosition = .atBottom
        state.updateState.setHasViewLoaded()
    }

    private func handleFirstResponder(_ oldValue: VScrollGeometry, _ newValue: VScrollGeometry) {
        if state.phase == .interacting {
            if newValue.offsetY < oldValue.offsetY {
                if oldValue.offsetY - newValue.offsetY > 20 {
                    UIApplication.shared.endEditing()
                }
            }
        }
    }

    private func onScrollViewSizeChange(
        _ oldValue: VScrollGeometry, _ newValue: VScrollGeometry
    ) {
        delegate?.layoutIfNeeded()
        guard oldValue.boundsSize.height != newValue.boundsSize.height else { return }
        let isFirstResponder = newValue.boundsHeight < oldValue.boundsHeight
        guard state.isFirstResponder != isFirstResponder else { return }
        state.isFirstResponder = isFirstResponder
        finalizeScrollUpdates()
        let diff = oldValue.boundsHeight - newValue.boundsHeight
        if state.scrolledPosition != .atBottom {
            let y = newValue.offsetY + diff
            scrollPosition.scrollTo(y: y)
        }
    }

    private func handleEffect(_ effect: ScrollReducer.Effect) {
        switch effect {
        case let .begingUpdate(updates): begin(updates: updates)
        case let .endUpdate(updates, item):
            state.updateState.update(to: .willBeginUpdates)
            if let item { performScroll(to: item) }
            Task { end(updates: updates) }
        }
    }

    private func begin(updates: DataUpdate) {
        scrollPosition = .init()
        var state = state
        state.phase = .animating
        state.updateState.update(to: .willBeginUpdates)
        state.paginationState = nil
        delegate?.scrollCoordinator(self, begin: updates)
        self.state = state
    }

    private func end(updates: DataUpdate) {
        switch updates {
        case let .insert(edge, geometry):
            switch edge {
            case .top: begin(updates: .remove(edge: .bottom, geometry: geometry))
            case .bottom: state.updateState.update(to: .didEndUpdates)
            }
        case let .remove(edge, _):
            switch edge {
            case .top: state.updateState.update(to: .didEndUpdates)
            case .bottom:
                state.updateState.update(to: .didEndUpdates)
                var state = state
                Task {
                    await Task.delay(0.2)
                    state.updateState.update(to: .didEndUpdates)
                    state.phase = .decelerating
                    self.state = state
                }
            }
        case .append: state.updateState.update(to: .didEndUpdates)
        case let .resetting(msg):
            state.updateState.update(to: .didEndUpdates)
            Task { performScroll(to: .id(msg.uid, anchor: .bottom, .animated())) }
        }
    }

    private func finalizeScrollUpdates() {
        state.scrolledPosition = state.geometry.scrolledPosition
        delegate?.scrollCoordinator(self, finalizeScrollViewUpdatesWith: state)
    }
}

extension ScrollCoordinator {
    func performScroll(to newValue: ScrollPositionItem) {
        switch newValue.properties {
        case let .animated(animation):
            withTransaction(.withAnimation(animation)) { scroll(to: newValue.position) }
        case .notAnimated:
            withTransaction(.withoutAnimation()) { scroll(to: newValue.position) }
        case .scroll: withTransaction(.scrollView()) { scroll(to: newValue.position) }
        }
    }

    private func scroll(to newValue: ScrollPositionValue) {
        switch newValue {
        case let .y(value): scrollPosition.scrollTo(y: value)
        case let .id(value, anchor): scrollPosition.scrollTo(id: value, anchor: anchor)
        case let .edge(edge):
            switch edge {
            case .top: scrollPosition.scrollTo(y: 0)
            case .bottom: scrollPosition.scrollTo(y: state.geometry.bottomMostOffset)
            default: break
            }
        }
    }
}
