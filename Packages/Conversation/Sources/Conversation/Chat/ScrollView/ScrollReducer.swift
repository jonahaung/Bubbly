//  ScrollReducer.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Foundation

struct ScrollReducer {
    enum Effect: Equatable {
        case begingUpdate(ScrollCoordinator.DataUpdate)
        case endUpdate(ScrollCoordinator.DataUpdate, scrollItem: ScrollPositionItem?)
    }
}

extension ScrollReducer {
    func reduceGeometry(
        newValue: VScrollGeometry,
        paginationState: PaginatableState?,
        phase: ScrollPhase,
        direction: ScrollDirection
    ) -> Effect? {
        guard let paginationState else { return nil }
        switch direction {
        case .up:
            let ratio = (newValue.offsetY+newValue.boundsHeight) / newValue.contentHeight
            if ratio > 0.9 {
                if paginationState.canLoadNewer {
                    return .begingUpdate(
                        paginationState.canAdjustSize && phase.isScrolling
                            ? .remove(edge: .top)
                            : .insert(edge: .bottom)
                    )
                }
            }
        case .down:
            let ratio = newValue.offsetY / newValue.contentHeight
            if ratio < 0.1, paginationState.canLoadOlder {
                return .begingUpdate(.insert(edge: .top))
            }
        case .none:
            let position = newValue.scrolledPosition
            if position == .atTop, paginationState.canLoadOlder {
                return .begingUpdate(.insert(edge: .top))
            }
            if position == .atBottom  {
                if paginationState.canLoadNewer {
                    return .begingUpdate(.insert(edge: .bottom))
                } else {
                   
                }
            }
            return nil
        }
        return nil
    }

    func handleUpdating(
        state: ScrollCoordinator.ScrollViewUpdate,
        oldValue: VScrollGeometry,
        newValue: VScrollGeometry
    ) -> Effect? {
        switch state {
        case let .dataUpdate(dataUpdate):
            switch dataUpdate {
            case let .insert(edge):
                let diff = newValue.contentHeight - oldValue.contentHeight
                guard diff != 0 else { return nil }
                if edge == .top {
                    let y =
                        diff + max(0, newValue.offsetY)
                    return .endUpdate(
                        .insert(edge: edge),
                        scrollItem: .y(y, .scroll)
                    )
                }
                return .endUpdate(
                    .insert(edge: edge), scrollItem: nil
                )
            case let .remove(edge):
                switch edge {
                case .top:
                    let diff = newValue.contentHeight - oldValue.contentHeight - (newValue.offsetY-oldValue.offsetY)
                    guard diff != 0 else { return nil }
                    let y = min(newValue.bottomMostOffset, newValue.offsetY) + diff
                    return .endUpdate(
                        .remove(edge: edge),
                        scrollItem: .y(y, .scroll)
                    )
                case .bottom:
                    return .endUpdate(.remove(edge: .bottom), scrollItem: nil)
                }
            case let .append(msg):
                return .endUpdate(
                    .append(msg: msg),
                    scrollItem: .id(msg.uid, .animated(.easeOut(duration: 0.2)))
                )
            case let .focus(msg):
                return .endUpdate(
                    .focus(msg: msg),
                    scrollItem: .y(
                        newValue.bottomMostOffset - (newValue.boundsHeight)
                    )
                )
            }
        default: return nil
        }
    }
}
