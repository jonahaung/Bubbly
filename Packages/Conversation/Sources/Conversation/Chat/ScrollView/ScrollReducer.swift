// © 2026 Aung Ko Min

import Core
import Foundation
import SwiftUI
import XUI

// MARK: - ScrollReducer
struct ScrollReducer {
    enum Effect: Equatable {
        case begingUpdate(ScrollCoordinator.DataUpdate)
        case endUpdate(
            ScrollCoordinator.DataUpdate,
            scrollItem: ScrollPositionItem?
        )
    }
}
extension ScrollReducer {
    func reduceGeometry(
        state: ScrollCoordinator.ScrollViewUpdate,
        oldValue: VScrollGeometry,
        newValue: VScrollGeometry,
        paginationState: ScrollCoordinator.PaginationState
    ) -> Effect? {
        if state.isUpdating {
            return handleUpdating(
                state: state,
                oldValue: oldValue,
                newValue: newValue
            )
        }
    
        let direction: ScrollCoordinator.ScrollDirection =
            newValue.offsetY >= oldValue.offsetY ? .up : .down
        return paginateIfNeeded(
            direction: direction,
            state,
            oldValue,
            newValue,
            paginationState: paginationState
        )
    }

    private func paginateIfNeeded(
        direction: ScrollCoordinator.ScrollDirection,
        _: ScrollCoordinator.ScrollViewUpdate,
        _ oldValue: VScrollGeometry,
        _ newValue: VScrollGeometry,
        paginationState: ScrollCoordinator.PaginationState
    ) -> Effect? {
        
        switch direction {
        case .down:
            if newValue.offsetY < ChatLayoutConstants.paginationTrashold  && oldValue.offsetY > newValue.offsetY {
                if paginationState.canLoadOlder {
                    return .begingUpdate(.insert(.top))
                }
            }
            return nil
        case .up:
            let atBottom =
                newValue.offsetY.rounded()
                > (newValue.contentHeight - newValue.boundsHeight).rounded()

            guard atBottom else {
                return nil
            }

            if paginationState.canLoadNewer {
                return .begingUpdate(
                    paginationState.canAdjustSize
                        ? .remove(.top) : .insert(.bottom),
                )
            }

            return paginationState.canAdjustSize
                ? .begingUpdate(.remove(.top)) : nil

        case .none:
            return nil
        }
    }

    func handleUpdating(
        state: ScrollCoordinator.ScrollViewUpdate,
        oldValue: VScrollGeometry,
        newValue: VScrollGeometry,
    ) -> Effect? {
        let diff = newValue.contentHeight - oldValue.contentHeight
        guard diff != 0 || state != .willEndUpdates else {
            return nil
        }
        switch state {
        case .insertingItems(let edge):
            if edge == .top {
                let y = diff + min(max(0, newValue.offsetY), ChatLayoutConstants.paginationTrashold)
                return .endUpdate(
                    .insert(edge),
                    scrollItem: .y(y, .scroll)
                )
            }
            return .endUpdate(.insert(edge), scrollItem: nil)

        case .removingItems(let edge):
            if edge == .top {
                let y =
                    newValue.offsetY + diff
                    + (newValue.offsetY - oldValue.offsetY)
                return .endUpdate(.remove(edge), scrollItem: .y(y, .scroll))
            }
            return .endUpdate(.remove(.bottom), scrollItem: nil)

        case .appendingItem(let id):
            if newValue.offsetY > newValue.bottomMostOffset - newValue
                .boundsHeight * 2
            {
                return .endUpdate(
                    .append(id),
                    scrollItem: .edge(.bottom, .animated(.snappy)),
                )
            }
            return .endUpdate(
                .append(id),
                scrollItem: .id(id, .animated()),
            )
        case .resetting(let msgID):
            return .endUpdate(
                .resetting(msgID),
                scrollItem: .y(
                    newValue.bottomMostOffset - (newValue.boundsHeight)
                )
            )
        default:
            return nil
        }
    }
}
