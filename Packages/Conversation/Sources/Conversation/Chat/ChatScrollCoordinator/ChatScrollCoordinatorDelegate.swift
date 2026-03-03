//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@MainActor
protocol ChatScrollCoordinatorDelegate: AnyObject {
    func scrollCoordinator(
        _ coordinator: ChatScrollCoordinator,
        shouldPaginateAt edge: VerticalEdge
    ) -> Bool
    func scrollCoordinator(
        _ coordinator: ChatScrollCoordinator,
        paginateAt edge: VerticalEdge
    )
    func scrollCoordinator(
        _ coordinator: ChatScrollCoordinator,
        removeAt edge: VerticalEdge
    )
    func scrollCoordinator(
        _ coordinator: ChatScrollCoordinator,
        finalizeUpdate state: ChatScrollCoordinator.State,
        newState: ChatScrollCoordinator.State
    )
}
