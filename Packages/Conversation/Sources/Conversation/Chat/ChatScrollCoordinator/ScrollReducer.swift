//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import XUI

struct ScrollReducer {

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
        canLoadNewer: Bool
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
                canLoadNewer: canLoadNewer
            )
        case let .onScrollPhaseChange(oldValue, newValue, context):
            guard oldValue != newValue else { return .noAction }
            if newValue == .idle {
                let geometry = VScrollGeometry(context.geometry)
                let y = geometry.offsetY
                if canLoadOlder, y < geometry.boundsHeight {
                    return .begingUpdate(.remove(edge: .bottom))
                }
            }
            return .noAction
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
        canLoadNewer: Bool
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
            canLoadNewer: canLoadNewer
        )
    }

    private func handleIdle(
        state: inout State,
        oldValue: VScrollGeometry,
        newValue: VScrollGeometry,
        canLoadOlder: Bool,
        canLoadNewer: Bool
    ) -> Effect {

        guard state.updateState.isNotUpdating, state.phase == .decelerating,
              oldValue.contentHeight == newValue.contentHeight
        else {
            return .noAction
        }
        if state.direction == .up, canLoadOlder, newValue.offsetY < newValue.boundsHeight / 2 {
            return .begingUpdate(.remove(edge: .bottom))
        }
        if state.direction == .down, canLoadNewer,
           newValue
           .offsetY + (newValue.boundsHeight + newValue.boundsHeight / 2)
           > newValue.contentHeight {
            return .begingUpdate(.insert(edge: .bottom))
        }
        return .noAction
    }

    private func handleUpdating(
        state: inout State,
        oldValue: VScrollGeometry,
        newValue: VScrollGeometry
    ) -> Effect {
        let difference = newValue.contentHeight - oldValue.contentHeight

        switch state.updateState {
        case .resetting:
            return .endUpdate(.reset, scrollItem: .snapToBottom())
        case let .insertingItems(edge):
            guard difference != 0 else {
                return .noAction
            }
            switch edge {
            case .top:
                let offsetY = newValue.offsetY + difference + (newValue.offsetY - oldValue.offsetY)
                return .endUpdate(.insert(edge: .top), scrollItem: .y(offsetY))
            case .bottom:
                return .endUpdate(.insert(edge: .bottom), scrollItem: nil)
            }
        case let .removingItems(edge):
            switch edge {
            case .top:
                return .noAction
            case .bottom:
                return .endUpdate(
                    .remove(edge: .bottom),
                    scrollItem: .y(oldValue.offsetY)
                )
            }
        case let .appendingItem(id):
            let offsetY = newValue.bottomMostOffset
            return .endUpdate(
                .append(id: id),
                scrollItem: .y(offsetY, animation: .easeIn(duration: 0.22))
            )
        default:
            return .noAction
        }
    }
}
