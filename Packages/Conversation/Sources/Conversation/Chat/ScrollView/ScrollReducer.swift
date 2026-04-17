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
        if newValue.offsetY <= ChatLayoutConstants.paginationTrashold
            && oldValue.offsetY > ChatLayoutConstants.paginationTrashold
        {
            if paginationState.canLoadOlder {
                return .begingUpdate(.insert(.top))
            }
        }
        let direction: ScrollCoordinator.ScrollDirection =
            newValue.offsetY > oldValue.offsetY ? .up : .down
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
        _ old: VScrollGeometry,
        _ new: VScrollGeometry,
        paginationState: ScrollCoordinator.PaginationState
    ) -> Effect? {
        switch direction {
        case .down:
            if new.offsetY <= 0 {
                if paginationState.canLoadOlder {
                    return .begingUpdate(.insert(.top))
                }
                return paginationState.canAdjustSize
                    ? .begingUpdate(.remove(.bottom)) : nil
            }
            return nil
        case .up:
            let atBottom =
                new.offsetY.rounded()
                > (new.contentHeight - new.boundsHeight).rounded()

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
                let y =
                    diff
                    + min(
                        ChatLayoutConstants.paginationTrashold,
                        max(0, newValue.offsetY)
                    )
                return .endUpdate(
                    .insert(edge),
                    scrollItem: .y(y, .notAnimated)
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
                    newValue.bottomMostOffset - (newValue.boundsHeight * 0.5)
                )
            )
        default:
            return nil
        }
    }
}
