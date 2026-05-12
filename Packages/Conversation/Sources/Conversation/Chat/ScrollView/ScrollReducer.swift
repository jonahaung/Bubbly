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
        paginationState: ScrollCoordinator.PaginationState,
        phase: ScrollPhase
    ) -> Effect? {
        let ratio = newValue.offsetY / newValue.contentHeight
        if ratio < 0.2, paginationState.canLoadOlder {
            return .begingUpdate(.insert(edge: .top, geometry: newValue))
        }
        if ratio > 0.85 {
            if paginationState.canLoadNewer {
                return .begingUpdate(
                    paginationState.canAdjustSize && phase.isScrolling
                        ? .remove(edge: .top, geometry: newValue)
                        : .insert(edge: .bottom, geometry: newValue)
                )
            }
        }
        return nil
    }

    func handleUpdating(
        state: ScrollCoordinator.ScrollViewUpdate, oldValue: VScrollGeometry,
        newValue: VScrollGeometry
    ) -> Effect? {
        switch state {
        case let .dataUpdate(dataUpdate):
            switch dataUpdate {
            case let .insert(edge, geometry):
                let diff = newValue.contentHeight - geometry.contentHeight
                guard diff != 0 else { return nil }
                if edge == .top {
                    let y =
                        diff + max(0, newValue.offsetY)
                        - (newValue.offsetY - geometry.offsetY)
                    return .endUpdate(
                        .insert(edge: edge, geometry: geometry),
                        scrollItem: .y(y, .scroll)
                    )
                }
                return .endUpdate(
                    .insert(edge: edge, geometry: newValue), scrollItem: nil
                )
            case let .remove(edge, geometry):
                switch edge {
                case .top:
                    let diff = newValue.contentHeight - geometry.contentHeight
                    guard diff != 0 else { return nil }
                    let y = max(0, newValue.offsetY) + diff
                    var newGeometry = newValue
                    newGeometry.offsetY = y
                    return .endUpdate(
                        .remove(edge: edge, geometry: newGeometry),
                        scrollItem: .y(y, .scroll)
                    )
                case .bottom:
                    return .endUpdate(.remove(edge: .bottom, geometry: newValue), scrollItem: nil)
                }
            case let .append(msg):
                return .endUpdate(
                    .append(msg: msg),
                    scrollItem: .id(msg.uid, .animated(.easeOut(duration: 0.2)))
                )
            case let .resetting(msg):
                return .endUpdate(
                    .resetting(msg: msg),
                    scrollItem: .y(
                        newValue.bottomMostOffset - (newValue.boundsHeight)
                    )
                )
            }
        default: return nil
        }
    }
}
