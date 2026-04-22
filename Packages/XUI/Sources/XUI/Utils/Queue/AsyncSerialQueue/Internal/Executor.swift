//  Executor.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Foundation

final class Executor: @unchecked Sendable {

    let taskPriority: TaskPriority?

    typealias closure = @Sendable () async -> Void
    private var task: Task<Void, Never>!
    private var taskStream: AsyncStream<closure>!
    private var continuation: AsyncStream<closure>.Continuation?

    init(priority: TaskPriority? = nil, _ completion: @Sendable @escaping () async -> Void = {}) {
        taskPriority = priority

        let taskStream = AsyncStream<closure>(bufferingPolicy: .unbounded) { continuation in
            self.continuation = continuation
        }
        self.taskStream = taskStream

        task = Task.detached(priority: priority) {
            for await closure in taskStream {
                await closure()

                if Task.isCancelled {
                    break
                }
            }

            await completion()
        }
    }

    func cancel() {
        task.cancel()
        continuation!.finish()
    }

    enum TaskState {
        case didQueue
        case didComplete
    }

    func async(_ closure: @escaping closure, block: @Sendable @escaping (TaskState, Task<Void, Never>) async -> Void = { _, _ in }) {
        continuation!.yield { [weak self] in
            guard let self else { return }

            let task = Task.detached(priority: taskPriority) {
                await closure()
            }

            await block(.didQueue, task)
            _ = await task.value
            await block(.didComplete, task)
        }
    }

}
