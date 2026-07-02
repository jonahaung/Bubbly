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
    @discardableResult
    func scrollCoordinator(
        _ coordinator: ScrollCoordinator,
        setEditing isEditing: Bool
    ) -> Bool
    func getPaginationState() -> PaginatableState?
    func layoutIfNeeded()
    var isFirstResponder: Bool { get }
}
