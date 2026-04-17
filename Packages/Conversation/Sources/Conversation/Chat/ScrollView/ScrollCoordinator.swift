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
    

    init() {}

    @ObservationIgnored weak var delegate: ScrollCoordinatorDelegate?
    @ObservationIgnored private(set) var state = State()
    @ObservationIgnored private var ignoredState = State()

    private var scrollPosition: ScrollPosition = .init()
    @ObservationIgnored private let scrollQueue: SerialTaskQueue = .init()
    @ObservationIgnored private let reducer: ScrollReducer = .init()

    var scrollPositionBindable: Binding<ScrollPosition> {
        .init(
            get: { [self] in
                scrollPosition
            },
            set: { _ in
            },
        )
    }
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
    private func getPaginationState() -> PaginationState {
        guard ignoredState.updateState.isNotUpdating else {
            return .init()
        }

        if let paginationState = ignoredState.paginationState {
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
            canAdjustSize: shouldAdjustWindow
        )
        ignoredState.paginationState = newValue
        return newValue
    }

    func send(_ intent: Intent) {
        switch intent {
        case .onScrollGeometryChange(let oldValue, let newValue):
            ignoredState.geometry = newValue
            guard state.updateState.hasViewLoaded else {
                handleHasViewLoaded(newValue)
                return
            }

            if ignoredState.updateState.isUpdating {
                if ignoredState.updateState == .willEndUpdates {
                    ignoredState.updateState.update(to: .didEndUpdates)
                    return
                }
                if let effect = reducer.handleUpdating(
                    state: ignoredState.updateState,
                    oldValue: oldValue,
                    newValue: newValue
                ) {
                    handleEffect(effect)
                }
                return
            }
            guard oldValue.boundsHeight == newValue.boundsHeight else {
                onScrollViewSizeChange(oldValue, newValue)
                return
            }

            if ignoredState.isFirstResponder {
                handleFirstResponder(oldValue, newValue)
            }
            if let effect = reducer.reduceGeometry(
                state: ignoredState.updateState,
                oldValue: oldValue,
                newValue: newValue,
                paginationState: getPaginationState()
            ) {
                handleEffect(effect)
            }
        case .onScrollPhaseChange(_, let newValue, let context):
            guard state.updateState.hasViewLoaded else {
                return
            }

            ignoredState.phase = newValue

            switch newValue {
            case .idle:
                finalizeScrollUpdates(geometry: .init(context.geometry))
            default:
                break
            }
        }
    }
}

extension ScrollCoordinator {
    fileprivate func handleHasViewLoaded(_ geometry: VScrollGeometry) {
        if geometry.scrolledPosition == .atBottom {
            ignoredState.scrolledPosition = .atBottom
            ignoredState.updateState.setHasViewLoaded()
            state = ignoredState
        } else {
            scrollPosition.scrollTo(y: geometry.bottomMostOffset)
        }
    }

    fileprivate func handleFirstResponder(
        _ oldValue: VScrollGeometry,
        _ newValue: VScrollGeometry,
    ) {
        if ignoredState.phase == .interacting {
            if newValue.offsetY < oldValue.offsetY {
                if oldValue.offsetY - newValue.offsetY > 20 {
                    UIApplication.shared.endEditing()
                }
            }
        }
    }

    fileprivate func onScrollViewSizeChange(
        _ oldValue: VScrollGeometry,
        _ newValue: VScrollGeometry,
    ) {
        guard ignoredState.updateState.hasViewLoaded else {
            return
        }
        delegate?.layoutIfNeeded()
        let isFirstResponder = newValue.boundsHeight < oldValue.boundsHeight
        guard ignoredState.isFirstResponder != isFirstResponder else {
            return
        }
        ignoredState.isFirstResponder = isFirstResponder
        let diff = oldValue.boundsHeight - newValue.boundsHeight
        guard abs(diff) > 200 else { return }
        guard isFirstResponder else {
            return
        }
        let y = newValue.offsetY + diff
        if ignoredState.scrolledPosition == .atBottom {
            scrollPosition = .init()
        } else {
            scrollPosition.scrollTo(y: y)
        }
    }

    fileprivate func handleEffect(_ effect: ScrollReducer.Effect) {
        switch effect {
        case .begingUpdate(let updates):
            begin(updates: updates)
        case .endUpdate(let updates, let item):
            if let item {
                performScroll(to: item)
            }
            end(updates: updates)
        }
    }

    fileprivate func begin(updates: DataUpdate) {
        ignoredState.updateState.update(to: .willBeginUpdates)
        ignoredState.paginationState = nil
        switch updates {
        case .insert(let edge):
            delegate?.scrollCoordinator(self, paginateAt: edge)
        case .remove(let edge):
            delegate?.scrollCoordinator(self, removeAt: edge)
        case .append(let id):
            ignoredState.updateState.update(to: .appendingItem(id))
        case .resetting:
            break
        }
    }

    fileprivate func end(updates value: DataUpdate) {
        switch value {
        case .insert(let edge):
            switch edge {
            case .top:
                begin(updates: .remove(.bottom))
            case .bottom:
                ignoredState.updateState.update(to: .didEndUpdates)
            }
        case .remove(let edge):
            switch edge {
            case .top:
                ignoredState.updateState.update(to: .didEndUpdates)
            case .bottom:
                ignoredState.updateState.update(to: .willEndUpdates)
            }
        case .append:
            ignoredState.updateState.update(to: .didEndUpdates)
        case .resetting(let msgID):
            Task {
                await Task.delay(0.5)
                performScroll(to: .id(msgID, anchor: .bottom, .animated()))
                ignoredState.updateState.update(to: .didEndUpdates)
            }
        }
    }

    fileprivate func finalizeScrollUpdates(geometry: VScrollGeometry) {
        ignoredState.geometry = geometry
        ignoredState.scrolledPosition = geometry.scrolledPosition
        delegate?.scrollCoordinator(
            self,
            finalizeUpdate: state,
            newState: ignoredState,
        )
        state = ignoredState
    }
}

extension ScrollCoordinator {
    func performScroll(to newValue: ScrollPositionItem) {
        scrollQueue.addTask { [weak self] completion in
            guard let self else {
                completion()
                return
            }

            switch newValue.properties {
            case .animated(let animation):
                let transaction = Transaction.withAnimation(animation) {
                    completion()
                }
                withTransaction(transaction) {
                    scroll(to: newValue.position)
                }
            case .notAnimated:
                let transaction = Transaction.withoutAnimation {
                    completion()
                }
                withTransaction(transaction) {
                    scroll(to: newValue.position)
                }
            case .scroll:
                let transaction = Transaction.scrollView {
                    completion()
                }
                withTransaction(transaction) {
                    scroll(to: newValue.position)
                }
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
                    y: ignoredState.geometry.bottomMostOffset
                )
            default:
                break
            }
        }
    }
}
