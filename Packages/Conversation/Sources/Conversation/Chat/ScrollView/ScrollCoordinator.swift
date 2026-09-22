//  ScrollCoordinator.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import Database
import ImageLoader
import Services
import SwiftUI
import XUI

@MainActor
@Observable
final class ScrollCoordinator {

    @ObservationIgnored
    weak var delegate: ScrollCoordinatorDelegate?

    @ObservationIgnored
    private let reducer: ScrollReducer = .init()

    @ObservationIgnored
    private var state: State = .init()

    @ObservationIgnored
    private var paginationState: PaginatableState?

    var scrollPosition: ScrollPosition

    init(lastPage: LastPage?) {
        scrollPosition = {
            if let lastPage {
                return .init(y: lastPage.scrollOffsetY)
            } else {
                return .init()
            }
        }()
    }
}

// MARK: - Derived State

extension ScrollCoordinator {

    var isFirstResponder: Bool {
        state.isFirstResponder
    }

    var updateState: ScrollViewUpdate {
        state.updateState
    }

    var geometry: VScrollGeometry {
        state.geometry
    }
}

// MARK: - Intent Handling

extension ScrollCoordinator {

    func send(_ intent: Intent) {
        switch intent {
        case .onScrollGeometryChange(let oldValue, let newValue):
            handleScrollGeometryChange(from: oldValue, to: newValue)

        case .onScrollPhaseChange(let oldValue, let newValue, let context):
            handleScrollPhaseChange(from: oldValue, to: newValue, context: context)

        case .begin(let update):
            begin(updates: update)
        }
    }

    private func handleScrollGeometryChange(from oldValue: VScrollGeometry, to newValue: VScrollGeometry) {
        guard state.updateState.hasViewLoaded else {
            handleViewLoaded(with: newValue)
            return
        }

        guard oldValue.boundsSize == newValue.boundsSize else {
            handleScrollViewSizeChange(from: oldValue, to: newValue)
            return
        }

        if state.updateState.isUpdating {
            handleUpdatingGeometry(from: oldValue, to: newValue)
        } else if state.isFirstResponder {
            handleFirstResponderGeometry(from: oldValue, to: newValue)
        } else {
            handlePaginationOnScroll(with: newValue)
        }
    }

    private func handleUpdatingGeometry(from oldValue: VScrollGeometry, to newValue: VScrollGeometry) {
        guard let effect = reducer.handleUpdating(state: state.updateState, oldValue: oldValue, newValue: newValue)
        else {
            return
        }
        handleEffect(effect)
    }

    private func handlePaginationOnScroll(with geometry: VScrollGeometry) {
        guard let paginationState, updateState == .didEndUpdates else { return }
        let topRatio = (geometry.offsetY - ChatLayoutConstants.topBarHeight) / geometry.contentHeight
        guard topRatio < 0.05, paginationState.canLoadOlder else { return }
        begin(updates: .insert(edge: .top))
    }

    private func handleScrollPhaseChange(
        from oldValue: ScrollPhase, to newValue: ScrollPhase, context: ScrollPhaseChangeContext
    ) {
        guard oldValue != newValue else { return }
        state.phase = newValue

        let geometry = VScrollGeometry(context.geometry)

        switch newValue {
        case .idle:
            handleIdlePhase(geometry: geometry)
        case .interacting:
            handleInteractingPhase()
        case .decelerating:
            handleDeceleratingPhase(geometry: geometry)
        default:
            break
        }
    }

    private func handleIdlePhase(geometry: VScrollGeometry) {
        state.geometry = geometry
        if updateState == .willEndUpdates {
            updateState(.didEndUpdates)
        }
        finalizeScrollUpdates()
    }

    private func handleInteractingPhase() {
        if updateState == .willEndUpdates {
            updateState(.didEndUpdates)
        }
    }

    private func handleDeceleratingPhase(geometry: VScrollGeometry) {
        guard updateState == .didEndUpdates, let paginationState else { return }
        let bottomRatio =
            (geometry.offsetY + ChatLayoutConstants.topBarHeight + geometry.boundsHeight) / geometry.contentHeight
        guard bottomRatio > 0.9 else { return }

        if paginationState.canAdjustSize {
            begin(updates: .remove(edge: .top))
        } else if paginationState.canLoadNewer {
            begin(updates: .insert(edge: .bottom))
        }
    }
    func updateState(_ update: ScrollViewUpdate) {
        state.updateState = update
    }
}

// MARK: - Pagination

extension ScrollCoordinator {

    private func paginateIfNeeded(_ geometry: VScrollGeometry, paginationState: PaginatableState) {
        guard let effect = reducer.reduceGeometry(newValue: geometry, paginationState: paginationState) else {
            return
        }
        handleEffect(effect)
    }

    private func updatePaginationState() {
        paginationState = delegate?.paginatableState()
    }
}

// MARK: - View Lifecycle Handlers

extension ScrollCoordinator {

    private func handleViewLoaded(with geometry: VScrollGeometry) {
        state.updateState.update(to: .didEndUpdates)
        if scrollPosition.y == nil {
            scrollPosition.scrollTo(edge: .bottom)
        }
        finalizeScrollUpdates()
        updatePaginationState()
    }

    private func handleFirstResponderGeometry(from oldValue: VScrollGeometry, to newValue: VScrollGeometry) {
        guard state.phase == .interacting else { return }
        guard newValue.offsetY < oldValue.offsetY else { return }
        delegate?.scrollCoordinator(self, setEditing: false)
    }

    private func handleScrollViewSizeChange(from oldValue: VScrollGeometry, to newValue: VScrollGeometry) {
        delegate?.layoutIfNeeded()

        guard oldValue.boundsSize.height != newValue.boundsSize.height,
            oldValue.boundsSize.width == newValue.boundsSize.width
        else {
            return
        }

        let isFirstResponder = newValue.boundsHeight < oldValue.boundsHeight && delegate?.isFirstResponder == true
        guard state.isFirstResponder != isFirstResponder else { return }
        state.isFirstResponder = isFirstResponder

        let diff = oldValue.boundsHeight - newValue.boundsHeight
        let y = newValue.offsetY + diff

        guard newValue.scrolledPosition != .atBottom else {
            if state.phase.isScrolling {
                performScroll(to: .y(y, .scroll))
            }
            return
        }

        let strategy: ScrollPositionItem.Properties = state.phase.isScrolling ? .notAnimated : .scroll
        performScroll(to: .y(y, strategy))
    }
}

// MARK: - Effects

extension ScrollCoordinator {

    private func handleEffect(_ effect: ScrollReducer.Effect) {
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
}

// MARK: - Update Lifecycle

extension ScrollCoordinator {

    private func begin(updates: DataUpdate) {
        paginationState = nil
        updateState(.willBeginUpdates)
        delegate?.scrollCoordinator(self, begin: updates)
    }

    private func end(updates: DataUpdate) {
        switch updates {
        case .remove(let edge):
            handleRemoval(edge: edge)

        case .insert(let edge):
            handleInsertion(edge: edge)

        case .focus(let message):
            handleFocus(message: message)
        }
    }

    private func handleRemoval(edge: VerticalEdge) {
        switch edge {
        case .top:
            updateState(.willEndUpdates)
        case .bottom:
            updateState(.didEndUpdates)
        }
        updatePaginationState()
    }

    private func handleInsertion(edge: VerticalEdge) {
        updatePaginationState()
        switch edge {
        case .top:
            if paginationState?.canAdjustSize == true {
                begin(updates: .remove(edge: .bottom))
            } else {
                updateState(.didEndUpdates)
            }
        case .bottom:
            updateState(.didEndUpdates)
        }
    }

    private func handleFocus(message: Message) {
        updateState(.didEndUpdates)
        Task.detached { [weak self] in
            guard let self else { return }
            await performScroll(to: .id(message.uid, anchor: .bottom, .animated()))
            await updatePaginationState()
        }
    }

    private func finalizeScrollUpdates() {
        delegate?.scrollCoordinator(self, finalizeScrollViewUpdatesWith: state)
        state.isFirstResponder = delegate?.isFirstResponder == true
    }

    func applicationDidBecomeActive() {
        finalizeScrollUpdates()
        updatePaginationState()
        if let paginationState {
            paginateIfNeeded(state.geometry, paginationState: paginationState)
        }
    }
}

// MARK: - Scrolling

extension ScrollCoordinator {

    func performScroll(to item: ScrollPositionItem) {
        switch item.properties {
        case .animated(let animation):
            performAnimatedScroll(animation: animation, to: item.position)

        case .notAnimated:
            performNonAnimatedScroll(to: item.position)

        case .scroll:
            performScrollPhaseAwareScroll(to: item.position)
        }
    }

    private func performAnimatedScroll(animation: Animation, to position: ScrollPositionValue) {
        withTransaction(
            .withAnimation(animation) { [weak self] in
                self?.scrollPosition = .init()
            }
        ) { [weak self] in
            self?.scroll(to: position)
        }
    }

    private func performNonAnimatedScroll(to position: ScrollPositionValue) {
        withTransaction(
            .withoutAnimation { [weak self] in
                self?.scrollPosition = .init()
            }
        ) { [weak self] in
            self?.scroll(to: position)
        }
    }

    private func performScrollPhaseAwareScroll(to position: ScrollPositionValue) {
        if state.phase.isScrolling {
            withTransaction(
                .scrollView { [weak self] in
                    self?.scrollPosition = .init()
                }
            ) { [weak self] in
                self?.scroll(to: position)
            }
        } else {
            performNonAnimatedScroll(to: position)
        }
    }

    private func scroll(to position: ScrollPositionValue) {
        switch position {
        case .y(let value):
            scrollPosition.scrollTo(y: value)

        case .id(let value, let anchor):
            scrollPosition.scrollTo(id: value, anchor: anchor)

        case .edge(let edge):
            scroll(to: edge)
        }
    }

    private func scroll(to edge: Edge) {
        switch edge {
        case .top:
            scrollPosition.scrollTo(y: 0)
        case .bottom:
            scrollPosition.scrollTo(edge: .bottom)
        default:
            break
        }
    }
}
