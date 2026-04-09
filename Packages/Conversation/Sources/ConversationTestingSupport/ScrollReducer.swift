// © 2026 Aung Ko Min

import Foundation
import SwiftUI

// MARK: - ScrollReducer

public struct ScrollReducer {
    public typealias State = ScrollCoordinator.State
    public typealias Intent = ScrollCoordinator.Intent
    public typealias DataUpdate = ScrollCoordinator.DataUpdate

    public enum Effect: Equatable, Sendable {
        case begingUpdate(DataUpdate)
        case endUpdate(DataUpdate, scrollItem: ScrollPositionItem?)
        case noAction
    }

    public init() {}
}

public extension ScrollReducer {
    func reduce(
        state: State,
        intent: Intent,
        canLoadOlder: Bool,
        canLoadNewer: Bool,
        shouldAdjustWindow: Bool,
    ) -> Effect {
        switch intent {
        case let .onScrollGeometryChange(old, new):
            reduceGeometry(
                state: state,
                oldValue: old,
                newValue: new,
                canLoadOlder: canLoadOlder,
                canLoadNewer: canLoadNewer,
                shouldAdjustWindow: shouldAdjustWindow,
            )
        default:
            .noAction
        }
    }
}

private extension ScrollReducer {
    enum Constants {
        static let paginationThreshold: CGFloat = 100
    }

    func reduceGeometry(
        state: State,
        oldValue: VScrollGeometry,
        newValue: VScrollGeometry,
        canLoadOlder: Bool,
        canLoadNewer: Bool,
        shouldAdjustWindow: Bool,
    ) -> Effect {
        if state.updateState.isUpdating {
            return handleUpdating(state: state, oldValue: oldValue, newValue: newValue)
        }

        if newValue.offsetY != oldValue.offsetY,
           state.phase == .interacting || state.phase == .decelerating
        {
            let direction: ScrollCoordinator.ScrollDirection =
                newValue.offsetY > oldValue.offsetY ? .up : .down

            return paginateIfNeeded(
                direction: direction,
                state,
                newValue,
                canLoadOlder,
                canLoadNewer,
                shouldAdjustWindow: shouldAdjustWindow,
            )
        }

        return .noAction
    }

    func paginateIfNeeded(
        direction: ScrollCoordinator.ScrollDirection,
        _: State,
        _ newValue: VScrollGeometry,
        _ canLoadOlder: Bool,
        _ canLoadNewer: Bool,
        shouldAdjustWindow: Bool,
    ) -> Effect {
        switch direction {
        case .down:
            guard newValue.offsetY <= Constants.paginationThreshold else {
                return .noAction
            }

            if canLoadOlder {
                return .begingUpdate(
                    shouldAdjustWindow ? .remove(edge: .bottom) : .insert(edge: .top),
                )
            }

            return shouldAdjustWindow ? .begingUpdate(.remove(edge: .bottom)) : .noAction

        case .up:
            let atBottom =
                newValue.offsetY.rounded() >=
                (newValue.contentHeight - newValue.boundsHeight).rounded()

            guard atBottom else {
                return .noAction
            }

            if canLoadNewer {
                return .begingUpdate(
                    shouldAdjustWindow ? .remove(edge: .top) : .insert(edge: .bottom),
                )
            }

            return shouldAdjustWindow ? .begingUpdate(.remove(edge: .top)) : .noAction

        case .none:
            return .noAction
        }
    }

    func handleUpdating(
        state: State,
        oldValue: VScrollGeometry,
        newValue: VScrollGeometry,
    ) -> Effect {
        let diff = newValue.contentHeight - oldValue.contentHeight
        guard diff != 0 else {
            return .noAction
        }

        switch state.updateState {
        case let .insertingItems(edge):
            if edge == .top {
                let y = diff + (newValue.offsetY - oldValue.offsetY)
                return .endUpdate(.insert(edge: edge), scrollItem: .y(y, properties: .scroll))
            }
            return .endUpdate(.insert(edge: edge), scrollItem: nil)

        case let .removingItems(edge):
            if edge == .top {
                let y = newValue.offsetY + diff + (newValue.offsetY - oldValue.offsetY)
                return .endUpdate(.remove(edge: edge), scrollItem: .y(y, properties: .scroll))
            }
            return .endUpdate(.remove(edge: .bottom), scrollItem: nil)

        case let .appendingItem(id):
            let y = newValue.offsetY + diff + (newValue.offsetY - oldValue.offsetY)
            return .endUpdate(
                .append(id: id),
                scrollItem: .y(y, properties: .animated(.easeOut(duration: 0.22))),
            )

        default:
            return .noAction
        }
    }
}
