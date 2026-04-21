// © 2026 Aung Ko Min

import Core
import Database
import ImageLoader
import OSLog
import Services
import SwiftUI
import XUI

@MainActor
@Observable
final class ScrollCoordinator {
    
    weak var delegate: ScrollCoordinatorDelegate?
    private let reducer: ScrollReducer = .init()
    private let throttler: Throttler = .init(delay: 0.5, option: .leading)
    private var state: State = .init()
    
    private var scrollPosition: ScrollPosition = .init()
    var scrollPositionBindable: Binding<ScrollPosition> {
        .init(get: { self.scrollPosition }, set: { _ in })
    }
}

extension ScrollCoordinator {
    func isNear(_ edge: VerticalEdge) -> Bool {
        state.geometry.isNear(edge)
    }

    func updateStateUpdate(to value: ScrollViewUpdate) {
        state.updateState.update(to: value)
    }

    func updatedState(is value: ScrollViewUpdate) -> Bool {
        state.updateState == value
    }
}

extension ScrollCoordinator {
    func send(_ intent: Intent) {
        switch intent {
        case .onScrollGeometryChange(let oldValue, let newValue):
            state.geometry = newValue
            guard state.updateState.hasViewLoaded else {
                handleHasViewLoaded(newValue)
                return
            }
            guard oldValue.boundsSize == newValue.boundsSize else {
                onScrollViewSizeChange(oldValue, newValue)
                return
            }
            let state = state
            if state.updateState.isUpdating {
                guard state.updateState.canReduceUpdates else {
                    return
                }
                if let effect = reducer.handleUpdating(
                    state: state.updateState,
                    oldValue: oldValue,
                    newValue: newValue,
                ) {
                    handleEffect(effect)
                }
            } else {
                if state.isFirstResponder {
                    handleFirstResponder(oldValue, newValue)
                    return
                }
                guard state.phase == .decelerating || state.phase == .interacting else {
                    return
                }
                if let effect = reducer.reduceGeometry(
                    state: state.updateState,
                    oldValue: oldValue,
                    newValue: newValue,
                    paginationState: getPaginationState(),
                ) {
                    handleEffect(effect)
                }
            }
        case .onScrollPhaseChange(let oldValue, let newValue, _):
            guard oldValue != newValue else {
                return
            }
            state.phase = newValue
            throttler.cancel()
            switch newValue {
            case .idle:
                throttler.throttle { [weak self] in
                    guard let self else {
                        return
                    }
                    finalizeScrollUpdates()
                }

            default:
                break
            }
        }
    }

    private func getPaginationState() -> PaginationState {
        if let paginationState = state.paginationState {
            return paginationState
        }
        func shouldPaginate(_ edge: VerticalEdge) -> Bool {
            delegate?.scrollCoordinator(self, shouldPaginateAt: edge) == true
        }
        let shouldAdjustWindow =
            delegate?.scrollCoordinatorShouldRemove(self) == true

        let newValue = PaginationState(
            canLoadOlder: shouldPaginate(.top),
            canLoadNewer: shouldPaginate(.bottom),
            canAdjustSize: shouldAdjustWindow,
        )
        state.paginationState = newValue
        return newValue
    }
}

extension ScrollCoordinator {
    private func handleHasViewLoaded(_ geometry: VScrollGeometry) {
        if geometry.scrolledPosition == .atBottom {
            state.scrolledPosition = .atBottom
            state.updateState.setHasViewLoaded()
        } else {
            scrollPosition.scrollTo(y: geometry.bottomMostOffset)
        }
    }

    private func handleFirstResponder(_ oldValue: VScrollGeometry, _ newValue: VScrollGeometry) {
        if state.phase == .interacting {
            if newValue.offsetY < oldValue.offsetY {
                if oldValue.offsetY - newValue.offsetY < 2 {
                    UIApplication.shared.endEditing()
                }
            }
        }
    }

    private func onScrollViewSizeChange(_ oldValue: VScrollGeometry, _ newValue: VScrollGeometry) {

        delegate?.layoutIfNeeded()
        guard
            oldValue.boundsSize.width == newValue.boundsSize.width,
            oldValue.boundsSize.height != newValue.boundsSize.height
        else {
            scrollPosition = .init(y: state.geometry.offsetY)
            return
        }
        let isFirstResponder = newValue.boundsHeight < oldValue.boundsHeight
        guard state.isFirstResponder != isFirstResponder else {
            return
        }
        state.isFirstResponder = isFirstResponder
        finalizeScrollUpdates()
        let diff = oldValue.boundsHeight - newValue.boundsHeight
        guard abs(diff) > 1 else {
            return
        }
        guard isFirstResponder else {
            return
        }
        if state.scrolledPosition == .atBottom {
            scrollPosition = .init()
        } else {
            let y = newValue.offsetY + diff
            scrollPosition.scrollTo(y: y)
        }
    }

    private func handleEffect(_ effect: ScrollReducer.Effect) {
        switch effect {
        case .begingUpdate(let updates):
            begin(updates: updates)
        case .endUpdate(let updates, let item):
            state.updateState.update(to: .willBeginUpdates)
            if let item {
                performScroll(to: item)
            }
            Task {
                end(updates: updates)
            }
        }
    }

    func begin(updates: DataUpdate) {
        state.updateState.update(to: .willBeginUpdates)
        state.paginationState = nil
        delegate?.scrollCoordinator(self, begin: updates)
    }

    private func end(updates: DataUpdate) {
        switch updates {
        case .insert(let edge, let geometry):
            switch edge {
            case .top:
                begin(updates: .remove(edge: .bottom, geometry: geometry))
            case .bottom:
                state.updateState.update(to: .didEndUpdates)
            }
        case .remove(let edge, _):
            switch edge {
            case .top:
                state.updateState.update(to: .didEndUpdates)
            case .bottom:
                state.updateState.update(to: .willEndUpdates)
                Task.detached { [weak self] in
                    guard let self else {
                        return
                    }
                    await Task.delay(0.5)
                    Task { @MainActor in
                        guard updatedState(is: .willEndUpdates) else {
                            return
                        }
                        state.updateState.update(to: .didEndUpdates)
                    }
                }
            }
        case .append:
            state.updateState.update(to: .didEndUpdates)
        case .resetting(let msg):
            state.updateState.update(to: .didEndUpdates)
            Task {
                performScroll(to: .id(msg.uid, anchor: .bottom, .animated()))
            }
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
        case .animated(let animation):
            withTransaction(.withAnimation(animation)) {
                scroll(to: newValue.position)
            }
        case .notAnimated:
            withTransaction(.withoutAnimation()) {
                scroll(to: newValue.position)
            }
        case .scroll:
            withTransaction(.scrollView()) {
                scroll(to: newValue.position)
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
                scrollPosition.scrollTo(
                    y: state.geometry.bottomMostOffset,
                )
            default:
                break
            }
        }
    }
}
