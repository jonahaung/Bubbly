// © 2026 Aung Ko Min

import Database
import SwiftUI

@MainActor
protocol ScrollCoordinatorDelegate: AnyObject {
    func scrollCoordinatorShouldRemove(
        _ coordinator: ScrollCoordinator,
    ) -> Bool
    func scrollCoordinator(
        _ coordinator: ScrollCoordinator,
        shouldPaginateAt edge: VerticalEdge,
    ) -> Bool
    func scrollCoordinator(
        _ coordinator: ScrollCoordinator,
        paginateAt edge: VerticalEdge,
    )
    func scrollCoordinator(
        _ coordinator: ScrollCoordinator,
        removeAt edge: VerticalEdge,
    )

    func scrollCoordinator(
        _ coordinator: ScrollCoordinator,
        state: ScrollCoordinator.State,
    )
    func layoutIfNeeded()
    func edgeMsg(at edge: VerticalEdge) -> Message?
}
