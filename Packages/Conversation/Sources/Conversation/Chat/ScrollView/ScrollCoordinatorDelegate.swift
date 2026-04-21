// © 2026 Aung Ko Min

import Database
import SwiftUI
import XUI

@MainActor
protocol ScrollCoordinatorDelegate: AnyObject {
    func scrollCoordinatorShouldRemove(_ coordinator: ScrollCoordinator) -> Bool
    func scrollCoordinator(_ coordinator: ScrollCoordinator, shouldPaginateAt edge: VerticalEdge) -> Bool
    func scrollCoordinator(_ coordinator: ScrollCoordinator, begin update: ScrollCoordinator.DataUpdate)
    func scrollCoordinator(_ coordinator: ScrollCoordinator, finalizeScrollViewUpdatesWith state: ScrollCoordinator.State,)
    func layoutIfNeeded()
}
