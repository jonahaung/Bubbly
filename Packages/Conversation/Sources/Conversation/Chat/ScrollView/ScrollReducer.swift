//  ScrollReducer.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import Foundation
import SwiftUI
import XUI

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
        newValue: VScrollGeometry,
        paginationState: PaginatableState?,
        phase: ScrollPhase,
        direction: ScrollDirection
    ) -> Effect? {
        guard let paginationState else { return nil }
        switch direction {
        case .up:
            let ratio =
                (newValue.offsetY + newValue.boundsHeight)
                / newValue.contentHeight
            if ratio > 0.85 {
                if paginationState.canLoadNewer {
                    return .begingUpdate(
                        paginationState.canAdjustSize && phase.isScrolling
                            ? .remove(edge: .top)
                            : .insert(edge: .bottom)
                    )
                }
            }
        case .down:
            let ratio = (newValue.offsetY) / newValue.contentHeight
            if ratio < 0.3, paginationState.canLoadOlder {
                return .begingUpdate(.insert(edge: .top))
            }
        case .none:
            if newValue.offsetY == 0, paginationState.canLoadOlder {
                return .begingUpdate(.insert(edge: .top))
            }
            if newValue.scrolledPosition == .atBottom {
                if paginationState.canLoadNewer {
                    return .begingUpdate(.insert(edge: .bottom))
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
        case .dataUpdate(let dataUpdate):
            switch dataUpdate {
            case .insert(let edge):
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
                    .insert(edge: edge),
                    scrollItem: nil
                )
            case .remove(let edge):
                switch edge {
                case .top:
                    let diff =
                        newValue.contentHeight - oldValue.contentHeight
                        - (newValue.offsetY - oldValue.offsetY)
                    guard diff != 0 else { return nil }
                    let y =
                        min(newValue.bottomMostOffset, newValue.offsetY) + diff
                    return .endUpdate(
                        .remove(edge: edge),
                        scrollItem: .y(y, .scroll)
                    )
                case .bottom:
                    return .endUpdate(.remove(edge: .bottom), scrollItem: nil)
                }
            case .append(let msg):
                return .endUpdate(
                    .append(msg: msg),
                    scrollItem: .edge(.bottom, .animated(.easeInExponential))
                )
            case .focus(let msg):
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
