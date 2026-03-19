//
//  ScrollCoordinatorDelegate.swift
//  Conversation
//
//  Created by Aung Ko Min on 11/3/26.
//

import SwiftUI

@MainActor
protocol ScrollCoordinatorDelegate: AnyObject {
	func scrollCoordinatorShouldRemove(
		_ coordinator: ScrollCoordinator
	) -> Bool
	func scrollCoordinator(
		_ coordinator: ScrollCoordinator,
		shouldPaginateAt edge: VerticalEdge
	) -> Bool
	func scrollCoordinator(
		_ coordinator: ScrollCoordinator,
		paginateAt edge: VerticalEdge
	)
	func scrollCoordinator(
		_ coordinator: ScrollCoordinator,
		removeAt edge: VerticalEdge
	)
	func scrollCoordinator(
		_ coordinator: ScrollCoordinator,
		resetAt edge: VerticalEdge
	)
	func scrollCoordinatorLayoutIfNeeded(
		_ coordinator: ScrollCoordinator
	)
	func scrollCoordinator(
		_ coordinator: ScrollCoordinator,
		finalizeUpdate state: ScrollCoordinator.State,
		newState: ScrollCoordinator.State
	)
}
