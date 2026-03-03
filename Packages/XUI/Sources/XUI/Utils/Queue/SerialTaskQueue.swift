//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol SerialTaskQueueProtocol {
    func addTask(_ task: sending @escaping SerialTaskQueue.TaskClosure)
    func start()
    func stop()
    func flushQueue()
    var isEmpty: Bool { get }
    var isStopped: Bool { get }
}

public final class SerialTaskQueue: SerialTaskQueueProtocol, Sendable {
    public typealias TaskClosure = (_ completion: @Sendable @escaping () -> Void) -> Void

    public private(set) nonisolated(unsafe) var isBusy = false
    public private(set) nonisolated(unsafe) var isStopped = true
    private nonisolated(unsafe) var tasksQueue = [TaskClosure]()

    public init() {
        start()
    }

    public func addTask(_ task: @escaping TaskClosure) {
        tasksQueue.append(task)
        maybeExecuteNextTask()
    }

    public func start() {
        isStopped = false
        maybeExecuteNextTask()
    }

    public func stop() {
        isStopped = true
    }

    public func flushQueue() {
        tasksQueue.removeAll()
    }

    public var isEmpty: Bool {
        tasksQueue.isEmpty
    }

    private func maybeExecuteNextTask() {
        if !isStopped, !isBusy {
            if !isEmpty {
                let firstTask = tasksQueue.removeFirst()
                isBusy = true
                firstTask { [weak self] () in
                    self?.isBusy = false
                    self?.maybeExecuteNextTask()
                }
            }
        }
    }
}
