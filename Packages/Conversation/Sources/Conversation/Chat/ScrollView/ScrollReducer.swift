//  ScrollReducer.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import Foundation
import SwiftUI
import XUI
import Database

struct ScrollReducer {

    enum Effect: Equatable {
        case begingUpdate(ScrollCoordinator.DataUpdate)
        case endUpdate(ScrollCoordinator.DataUpdate, scrollItem: ScrollPositionItem?)
    }
}

// MARK: - Geometry Reduction

extension ScrollReducer {

    func reduceGeometry(newValue: VScrollGeometry, paginationState: PaginatableState) -> Effect? {
        if let effect = reduceBottomEdge(newValue: newValue, paginationState: paginationState) {
            return effect
        }
        return reduceTopEdge(newValue: newValue, paginationState: paginationState)
    }

    private func reduceBottomEdge(newValue: VScrollGeometry, paginationState: PaginatableState) -> Effect? {
        let bottomRatio = (newValue.offsetY + newValue.boundsHeight) / newValue.contentHeight
        guard bottomRatio > 0.9 else { return nil }
        guard paginationState.canLoadNewer else { return nil }
        return .begingUpdate(.insert(edge: .bottom))
    }

    private func reduceTopEdge(newValue: VScrollGeometry, paginationState: PaginatableState) -> Effect? {
        let topRatio = (newValue.offsetY - ChatLayoutConstants.topBarHeight) / newValue.contentHeight
        guard topRatio < 0.05 else { return nil }
        guard paginationState.canLoadOlder else { return nil }
        return .begingUpdate(.insert(edge: .top))
    }
}

// MARK: - Updating

extension ScrollReducer {

    func handleUpdating(
        state: ScrollCoordinator.ScrollViewUpdate,
        oldValue: VScrollGeometry,
        newValue: VScrollGeometry
    ) -> Effect? {
        guard case .dataUpdate(let dataUpdate) = state else { return nil }

        switch dataUpdate {
        case .insert(let edge):
            return handleInsert(edge: edge, dataUpdate: dataUpdate, oldValue: oldValue, newValue: newValue)

        case .remove(let edge):
            return handleRemove(edge: edge, dataUpdate: dataUpdate, oldValue: oldValue, newValue: newValue)

        case .focus(let message):
            return handleFocus(message: message, newValue: newValue)
        }
    }

    private func handleInsert(
        edge: VerticalEdge,
        dataUpdate: ScrollCoordinator.DataUpdate,
        oldValue: VScrollGeometry,
        newValue: VScrollGeometry
    ) -> Effect? {
        switch edge {
        case .top:
            guard let y = scrollOffsetAfterInsertion(oldValue: oldValue, newValue: newValue) else { return nil }
            return .endUpdate(dataUpdate, scrollItem: .y(y, .scroll))

        case .bottom:
            return .endUpdate(dataUpdate, scrollItem: nil)
        }
    }

    private func handleRemove(
        edge: VerticalEdge,
        dataUpdate: ScrollCoordinator.DataUpdate,
        oldValue: VScrollGeometry,
        newValue: VScrollGeometry
    ) -> Effect? {
        switch edge {
        case .top:
            guard let y = scrollOffsetAfterRemoval(oldValue: oldValue, newValue: newValue) else { return nil }
            return .endUpdate(dataUpdate, scrollItem: .y(y, .scroll))

        case .bottom:
            return .endUpdate(dataUpdate, scrollItem: nil)
        }
    }

    private func handleFocus(message: Message, newValue: VScrollGeometry) -> Effect {
        .endUpdate(
            .focus(msg: message),
            scrollItem: .y(newValue.bottomMostOffset - newValue.boundsHeight)
        )
    }
}

// MARK: - Offset Calculations

extension ScrollReducer {

    private func contentOffsetDelta(oldValue: VScrollGeometry, newValue: VScrollGeometry) -> CGFloat {
        newValue.contentHeight - oldValue.contentHeight - (newValue.offsetY - oldValue.offsetY)
    }

    private func scrollOffsetAfterInsertion(oldValue: VScrollGeometry, newValue: VScrollGeometry) -> CGFloat? {
        let diff = contentOffsetDelta(oldValue: oldValue, newValue: newValue)
        guard diff != 0 else { return nil }
        return diff + newValue.offsetY
    }

    private func scrollOffsetAfterRemoval(oldValue: VScrollGeometry, newValue: VScrollGeometry) -> CGFloat? {
        let diff = contentOffsetDelta(oldValue: oldValue, newValue: newValue)
        guard diff != 0 else { return nil }
        return newValue.offsetY + diff
    }
}
