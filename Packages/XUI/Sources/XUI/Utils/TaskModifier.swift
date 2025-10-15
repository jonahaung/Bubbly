//
//  TaskModifier.swift
//  XUI
//
//  Created by Aung Ko Min on 9/7/25.
//

import SwiftUI

public struct TaskModifier<T: Equatable>: ViewModifier {
    private let id: T
    private let priority: TaskPriority
    private let action: @Sendable () async -> Void

    @State private var task: Task<Void, Never>?

    public init(
        id: T,
        priority: TaskPriority = .userInitiated,
        action: @escaping @Sendable () async -> Void
    ) {
        self.id = id
        self.priority = priority
        self.action = action
    }

    public func body(content: Content) -> some View {
        content
            .onAppear {
                self.task = Task(priority: priority, operation: action)
            }
            .onDisappear {
                self.task?.cancel()
                self.task = nil
            }
            .onChange(of: self.id) { _, _ in
                self.task?.cancel()
                self.task = Task(priority: priority, operation: action)
            }
    }
}

public extension View {
	func onTask<T: Equatable>(
		id: T,
		priority: TaskPriority = .userInitiated,
		_ action: @escaping @Sendable () async -> Void
	) -> some View {
		modifier(TaskModifier(id: id, priority: priority, action: action))
	}
}
