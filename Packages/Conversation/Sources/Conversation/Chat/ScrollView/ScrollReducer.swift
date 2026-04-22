// © 2026 Aung Ko Min

import Core
import Foundation
import SwiftUI
import XUI

struct ScrollReducer {
    enum Effect: Equatable {
        case begingUpdate(ScrollCoordinator.DataUpdate)
        case endUpdate(
            ScrollCoordinator.DataUpdate,
            scrollItem: ScrollPositionItem?,
        )
    }
}

extension ScrollReducer {
    func reduceGeometry(
        newValue: VScrollGeometry,
        paginationState: ScrollCoordinator.PaginationState,
    ) -> Effect? {
        let ratio = newValue.offsetY / newValue.contentHeight
        if ratio < 0.1, paginationState.canLoadOlder {
            return .begingUpdate(.insert(edge: .top, geometry: newValue))
        }
        if ratio > 0.85 {
            if paginationState.canLoadNewer {
                return .begingUpdate(
                    paginationState.canAdjustSize
                        ? .remove(edge: .top, geometry: newValue) : .insert(edge: .bottom, geometry: newValue),
                )
            }
            return paginationState.canAdjustSize
                ? .begingUpdate(.remove(edge: .top, geometry: newValue)) : nil
        }
        return nil
    }

    func handleUpdating(
        state: ScrollCoordinator.ScrollViewUpdate,
        oldValue: VScrollGeometry,
        newValue: VScrollGeometry,
    ) -> Effect? {
        switch state {
        case .dataUpdate(let dataUpdate):
            switch dataUpdate {
            case .insert(let edge, let geometry):
                let diff = newValue.contentHeight - geometry.contentHeight
                guard diff != 0 else {
                    return nil
                }
                if edge == .top {
                    let y = diff + newValue.offsetY + (newValue.offsetY - geometry.offsetY)
                    return .endUpdate(
                        .insert(edge: edge, geometry: geometry),
                        scrollItem: .y(y, .scroll),
                    )
                }
                return .endUpdate(.insert(edge: edge, geometry: newValue), scrollItem: nil)

            case .remove(let edge, let geometry):
                if edge == .top {
                    let diff = newValue.contentHeight - geometry.contentHeight
                    let y = newValue.offsetY + diff + (newValue.offsetY - oldValue.offsetY)
                    var newGeometry = newValue
                    newGeometry.offsetY = y
                    return .endUpdate(.remove(edge: edge, geometry: newGeometry), scrollItem: .y(y, .scroll))
                }
                return .endUpdate(.remove(edge: .bottom, geometry: newValue), scrollItem: nil)

            case .append(let id):
                return .endUpdate(.append(msgID: id), scrollItem: .id(id, .animated(.easeOut(duration: 0.2))))

            case .resetting(let msg):
                return .endUpdate(.resetting(msg: msg), scrollItem: .y(newValue.bottomMostOffset - (newValue.boundsHeight)))
            }
        default:
            return nil
        }

    }
}
