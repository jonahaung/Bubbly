//  ScrollCoordinatorDelegate.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database
import SwiftUI
import XUI

protocol ScrollCoordinatorDelegate: AnyObject {
    func scrollCoordinator(
        _ coordinator: ScrollCoordinator,
        begin update: ScrollCoordinator.DataUpdate
    )
    func scrollCoordinator(
        _ coordinator: ScrollCoordinator,
        finalizeScrollViewUpdatesWith state: ScrollCoordinator.State
    )
    func getPaginationState() -> PaginatableState?
    func layoutIfNeeded()
}
