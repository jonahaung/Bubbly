//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import XUI

enum ScrollReducer {

    typealias State = ChatScrollCoordinator.State
    typealias Intent = ChatScrollCoordinator.Intent
    typealias DataUpdate = ChatScrollCoordinator.DataUpdate

    enum Effect: Equatable {
        case scroll(item: ScrollPositionItem)
        case begingUpdate(_ updates: DataUpdate)
        case endUpdate(_ updates: DataUpdate, scrollItem: ScrollPositionItem?)
        case finalizeScrollViewUpdates
        case removePendingUpdates
        case noAction
    }
}

extension ScrollReducer {
    func reduce(
        state: inout State,
        intent: Intent,
        canLoadOlder: Bool,
        canLoadNewer: Bool,
        shouldAdjustWindow: Bool
    ) -> Effect {
        switch intent {
        case let .onVisibilityChange(visibility):
            switch visibility {
            case .visible, .automatic:
                return .scroll(item: .edge(.bottom))
            case .hidden:
                return .noAction
            }
        case let .onScrollGeometryChange(oldValue, newValue):
            return reduceGeometry(
                state: &state,
                oldValue: oldValue,
                newValue: newValue,
                canLoadOlder: canLoadOlder,
                canLoadNewer: canLoadNewer,
                canRemove: shouldAdjustWindow
            )
        default:
            return .noAction
        }
    }
}

extension ScrollReducer {
    private func reduceGeometry(
        state: inout State,
        oldValue: VScrollGeometry,
        newValue: VScrollGeometry,
        canLoadOlder: Bool,
        canLoadNewer: Bool,
        canRemove: Bool
    ) -> Effect {

        guard state.updateState.hasViewLoaded else {
            return .noAction
        }

        if state.updateState.isUpdating {
            return handleUpdating(state: &state, oldValue: oldValue, newValue: newValue)
        }

        return handleIdle(
            state: &state,
            oldValue: oldValue,
            newValue: newValue,
            canLoadOlder: canLoadOlder,
            canLoadNewer: canLoadNewer,
            shouldAdjustWindow: canRemove
        )
    }

    private func paginateIfNeeded(
        _ state: ScrollReducer.State,
        _ newValue: VScrollGeometry,
        _ canLoadOlder: Bool,
        _ canLoadNewer: Bool,
        shouldAdjustWindow: Bool
    ) -> ScrollReducer.Effect {
        if state.direction == .up, canLoadOlder, newValue.canPaginate(at: .top) {
            return .begingUpdate(shouldAdjustWindow ? .remove(edge: .bottom) : .insert(edge: .top))
        }
        if state.direction == .down, canLoadNewer,
           newValue.canPaginate(at: .bottom) {
            return .begingUpdate(shouldAdjustWindow ? .remove(edge: .top) : .insert(edge: .bottom))
        }
        return .noAction
    }

    private func handleIdle(
        state: inout State,
        oldValue: VScrollGeometry,
        newValue: VScrollGeometry,
        canLoadOlder: Bool,
        canLoadNewer: Bool,
        shouldAdjustWindow: Bool
    ) -> Effect {

        guard state.updateState.isNotUpdating,
              [ScrollPhase.decelerating, .interacting]
              .contains(state.phase),
              oldValue.contentHeight == newValue.contentHeight
        else {
            return .noAction
        }
        return paginateIfNeeded(
            state,
            newValue,
            canLoadOlder,
            canLoadNewer,
            shouldAdjustWindow: shouldAdjustWindow
        )
    }

    private func handleUpdating(
        state: inout State,
        oldValue: VScrollGeometry,
        newValue: VScrollGeometry
    ) -> Effect {
        let difference = newValue.contentHeight - oldValue.contentHeight

        switch state.updateState {
        case .resetting:
            guard difference != 0 else {
                return .scroll(item: .y(newValue.offsetY))
            }
            return .endUpdate(.reset, scrollItem: .snapToBottom())
        case let .insertingItems(edge):
            switch edge {
            case .top:
                let offsetY = newValue.offsetY + difference + (newValue.offsetY - oldValue.offsetY)
                return .endUpdate(.insert(edge: edge), scrollItem: .y(offsetY))
            case .bottom:
                return .endUpdate(.insert(edge: edge), scrollItem: nil)
            }
        case let .removingItems(edge):
            switch edge {
            case .top:

                let offsetY = newValue.offsetY + difference + (newValue.offsetY - oldValue.offsetY)
                return .endUpdate(
                    .remove(edge: edge),
                    scrollItem: .y(offsetY)
                )
            case .bottom:
                return .endUpdate(
                    .remove(edge: edge),
                    scrollItem: .y(newValue.offsetY)
                )
            }
        case let .appendingItem(id):
            return .endUpdate(
                .append(id: id),
                scrollItem: .id(id, animation: .interactiveSpring(duration: 0.4))
            )
        default:
            return .noAction
        }
    }
}
