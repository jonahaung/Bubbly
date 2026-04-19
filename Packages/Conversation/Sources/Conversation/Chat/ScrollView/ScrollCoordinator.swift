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
    
    weak var delegate: ScrollCoordinatorDelegate?
    private let reducer: ScrollReducer = .init()
    
    private var safeScrollPosition: AtomicQueue<ScrollPosition> = .init(.init())
    private var scrollPosition: ScrollPosition {
        get { safeScrollPosition.wrappedValue }
        set { safeScrollPosition.wrappedValue = newValue }
    }
    var scrollPositionBindable: Binding<ScrollPosition> { .init(get: { self.scrollPosition }, set: { _ in })}
    
    @ObservationIgnored
    private var safeState: SafeStorage<State> = .init(.init())
    private var state: State {
        get { safeState.value }
        set { safeState.value = newValue }
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
    private func getPaginationState() -> PaginationState {
        guard state.updateState.isNotUpdating else {
            return .init()
        }

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
            canAdjustSize: shouldAdjustWindow
        )
        state.paginationState = newValue
        return newValue
    }

    func send(_ intent: Intent) {
        switch intent {
        case .onScrollGeometryChange(let oldValue, let newValue):
            state.geometry = newValue
            guard state.updateState.hasViewLoaded else {
                handleHasViewLoaded(newValue)
                return
            }
            if state.isFirstResponder {
                handleFirstResponder(oldValue, newValue)
                return
            }
            guard oldValue.boundsSize == newValue.boundsSize else {
                onScrollViewSizeChange(oldValue, newValue)
                return
            }
            if state.updateState.isUpdating {
                if state.updateState == .willEndUpdates {
                    state.updateState.update(to: .didEndUpdates)
                    return
                }
                if let effect = reducer.handleUpdating(
                    state: state.updateState,
                    oldValue: oldValue,
                    newValue: newValue
                ) {
                    handleEffect(effect)
                }
                return
            }
        
            guard newValue.offsetY <= ChatLayoutConstants.paginationTrashold
                    || newValue.offsetY >= (newValue.contentHeight - newValue.boundsHeight) && state.phase == .decelerating
            else {
                return
            }
            if let effect = reducer.reduceGeometry(
                state: state.updateState,
                oldValue: oldValue,
                newValue: newValue,
                paginationState: getPaginationState()
            ) {
                handleEffect(effect)
            }
        case .onScrollPhaseChange(_, let newValue, let context):
            state.phase = newValue
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
            state.scrolledPosition = .atBottom
            state.updateState.setHasViewLoaded()
            state = state
           
        } else {
            scrollPosition.scrollTo(y: geometry.bottomMostOffset)
        }
    }

    fileprivate func handleFirstResponder(
        _ oldValue: VScrollGeometry,
        _ newValue: VScrollGeometry,
    ) {
        if state.phase == .interacting {
            if newValue.offsetY < oldValue.offsetY {
                if oldValue.offsetY - newValue.offsetY < 10 {
                    UIApplication.shared.endEditing()
                }
            }
        }
    }

    fileprivate func onScrollViewSizeChange(
        _ oldValue: VScrollGeometry,
        _ newValue: VScrollGeometry,
    ) {

        delegate?.layoutIfNeeded()
        guard
            oldValue.boundsSize.width == newValue.boundsSize.width
                && oldValue.boundsSize.height != newValue.boundsSize.height
        else {
            scrollPosition = .init(y: state.geometry.offsetY)
            return
        }
        let isFirstResponder = newValue.boundsHeight < oldValue.boundsHeight
        guard state.isFirstResponder != isFirstResponder else {
            return
        }
        state.isFirstResponder = isFirstResponder
        let diff = oldValue.boundsHeight - newValue.boundsHeight
        guard abs(diff) > 1 else { return }
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
        scrollPosition = .init()
        state.updateState.update(to: .willBeginUpdates)
        state.paginationState = nil
        switch updates {
        case .insert(let edge):
            delegate?.scrollCoordinator(self, paginateAt: edge)
        case .remove(let edge):
            delegate?.scrollCoordinator(self, removeAt: edge)
        case .append(let id):
            state.updateState.update(to: .appendingItem(id))
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
                state.updateState.update(to: .didEndUpdates)
            }
        case .remove(let edge):
            switch edge {
            case .top:
                state.updateState.update(to: .didEndUpdates)
            case .bottom:
                state.updateState.update(to: .didEndUpdates)
            }
        case .append:
            state.updateState.update(to: .didEndUpdates)
        case .resetting(let msgID):
            Task {
                performScroll(to: .id(msgID, anchor: .bottom, .animated()))
                state.updateState.update(to: .didEndUpdates)
            }
        }
    }

    fileprivate func finalizeScrollUpdates(geometry: VScrollGeometry) {
        state.geometry = geometry
        state.scrolledPosition = geometry.scrolledPosition
        delegate?.scrollCoordinator(self, state: state)
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
                    y: state.geometry.bottomMostOffset
                )
            default:
                break
            }
        }
    }
}
