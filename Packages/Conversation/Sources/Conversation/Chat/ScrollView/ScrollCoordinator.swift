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

    @ObservationIgnored
    weak var delegate: ScrollCoordinatorDelegate?
    @ObservationIgnored
    private let reducer: ScrollReducer = .init()
    @ObservationIgnored
    private let debouncer: Debouncer = .init(delay: 0.5)
    @ObservationIgnored
    private var state: State = .init()
    @ObservationIgnored
    private var scrollDirection: ScrollDirection = .none

    private var scrollPosition: ScrollPosition
    @ObservationIgnored
    var scrollPositionBindable: Binding<ScrollPosition> {
        .init(get: { self.scrollPosition }, set: { _ in })
    }

    init(_ lastPage: LastPage?) {
        scrollPosition = {
            if let lastPage {
                return .init(y: lastPage.scrollOffsetY)
            } else {
                return .init()
            }
        }()
    }
}

extension ScrollCoordinator {
    var isFirstResponder: Bool { state.isFirstResponder }
    var updateState: ScrollViewUpdate { state.updateState }
    var geometry: VScrollGeometry { state.geometry }

    func updateState(_ update: ScrollViewUpdate) {
        state.updateState = update
    }
}

extension ScrollCoordinator {
    func send(_ intent: Intent) {
        switch intent {
        case .onScrollGeometryChange(let oldValue, let newValue):
            guard state.updateState.hasViewLoaded else {
                handleHasViewLoaded(newValue)
                return
            }
            guard oldValue.boundsSize == newValue.boundsSize else {
                onScrollViewSizeChange(oldValue, newValue)
                return
            }
            if state.updateState.isUpdating {
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
                if newValue.offsetY < 0 {
                    scrollPosition.scrollTo(y: 0)
                }
            }
        case .onScrollPhaseChange(let oldValue, let newValue, let context):
            guard oldValue != newValue else { return }
            state.phase = newValue
            let geometry = VScrollGeometry(context.geometry)
            switch newValue {
            case .idle:
                let position = geometry.scrolledPosition
                if position == .atTop || position == .atBottom {
                    paginateIfNeeded(geometry, state: state, direction: .none)
                }
                state.geometry = geometry
                debouncer.debounce { [weak self] in
                    guard let self else { return }
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        finalizeScrollUpdates()
                    }
                }
            case .interacting:
                debouncer.cancel()
//                paginateIfNeeded(
//                    geometry,
//                    state: state,
//                    direction: scrollDirection
//                )
            case .decelerating:
                if let dy = context.velocity?.dy, abs(dy) != 0 {
                    let direction = dy < 0 ? ScrollDirection.down : .up
                    if scrollDirection != direction {
                        scrollDirection = direction
                    }
                }
                paginateIfNeeded(
                    geometry,
                    state: state,
                    direction: scrollDirection
                )
            default:
                break
            }
        case .begin(let update):
            begin(updates: update)
        }
    }

    private func paginateIfNeeded(
        _ geometry: VScrollGeometry,
        state: State,
        direction: ScrollDirection
    ) {
        if state.updateState.isNotUpdating {
            if let effect = reducer.reduceGeometry(
                newValue: geometry,
                paginationState: paginatedState(),
                phase: state.phase,
                direction: direction
            ) {
                handleEffect(effect)
            }
        }
    }

    private func paginatedState() -> PaginatableState? {
        delegate?.getPaginationState()
    }
}

extension ScrollCoordinator {

    fileprivate func handleHasViewLoaded(_ geometry: VScrollGeometry) {
        if scrollPosition.y == nil {
            scrollPosition.scrollTo(y: geometry.bottomMostOffset)
        }
        state.updateState.update(to: .didEndUpdates)
        debouncer.debounce { [weak self] in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                finalizeScrollUpdates()
            }
        }
    }

    private func handleFirstResponder(
        _ oldValue: VScrollGeometry,
        _ newValue: VScrollGeometry
    ) {
        if state.phase == .interacting {
            if newValue.offsetY < oldValue.offsetY {
                UIApplication.shared.endEditing()
            }
        }
    }

    fileprivate func onScrollViewSizeChange(
        _ oldValue: VScrollGeometry,
        _ newValue: VScrollGeometry
    ) {
        delegate?.layoutIfNeeded()
        guard oldValue.boundsSize.height != newValue.boundsSize.height,
            oldValue.boundsSize.width == newValue.boundsSize.width
        else {
            return
        }
        let isFirstResponder =
            newValue.boundsHeight < oldValue.boundsHeight
            && !UIApplication.shared.isFirstResponder
        guard state.isFirstResponder != isFirstResponder else { return }
        state.isFirstResponder = isFirstResponder
        if oldValue.scrolledPosition != .atBottom {
            let diff = oldValue.boundsHeight - newValue.boundsHeight
            let y = newValue.offsetY + diff
            if isFirstResponder {
                scrollPosition.scrollTo(y: y)
            } else {
                performScroll(to: .y(y, .scroll))
            }

        }
    }

    fileprivate func handleEffect(_ effect: ScrollReducer.Effect) {
        switch effect {
        case .begingUpdate(let updates):
            begin(updates: updates)
        case .endUpdate(let updates, let item):
            if let item { performScroll(to: item) }
            Task.detached { [weak self] in
                guard let self else { return }
                await end(updates: updates)
            }
        }
    }

    fileprivate func begin(updates: DataUpdate) {
        updateState(.willBeginUpdates)
        delegate?.scrollCoordinator(self, begin: updates)
    }

    fileprivate func end(updates: DataUpdate) {
        scrollDirection = .none
        switch updates {
        case .append, .remove:
            updateState(.didEndUpdates)
        case .insert(let edge):
            switch edge {
            case .top:
                if state.phase.isScrolling {
                    begin(updates: .remove(edge: .bottom))
                } else {
                    updateState(.didEndUpdates)
                }
            case .bottom:
                updateState(.didEndUpdates)
            }
        case .focus(let msg):
            updateState(.didEndUpdates)
            Task.detached { [weak self] in
                guard let self else { return }
                await performScroll(
                    to: .id(msg.uid, anchor: .bottom, .animated())
                )
            }
        }
    }

    fileprivate func finalizeScrollUpdates() {
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
                    scrollPosition.isPositionedByUser = true
                }
            ) { scroll(to: newValue.position) }
        case .notAnimated:
            withTransaction(
                .withoutAnimation { [weak self] in
                    guard let self else { return }
                    scrollPosition.isPositionedByUser = true
                }
            ) { scroll(to: newValue.position) }
        case .scroll:
            if state.phase.isScrolling {
                withTransaction(
                    .scrollView { [weak self] in
                        guard let self else { return }
                        scrollPosition.isPositionedByUser = true
                    }
                ) { scroll(to: newValue.position) }
            } else {
                withTransaction(
                    .withoutAnimation { [weak self] in
                        guard let self else { return }
                        scrollPosition.isPositionedByUser = true
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
