//
//  SerialTaskQueueProtocol.swift
//  XUI
//
//  Created by Aung Ko Min on 27/9/25.
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

	nonisolated(unsafe)
    public private(set) var isBusy = false
	nonisolated(unsafe)
    public private(set) var isStopped = true
	nonisolated(unsafe)
    private var tasksQueue = [TaskClosure]()

    public init() {
		start()
	}

    public func addTask(_ task: @escaping TaskClosure) {
        self.tasksQueue.append(task)
        self.maybeExecuteNextTask()
    }

    public func start() {
        self.isStopped = false
        self.maybeExecuteNextTask()
    }

    public func stop() {
        self.isStopped = true
    }

    public func flushQueue() {
        self.tasksQueue.removeAll()
    }

    public var isEmpty: Bool {
        return self.tasksQueue.isEmpty
    }

    private func maybeExecuteNextTask() {
        if !self.isStopped && !self.isBusy {
            if !self.isEmpty {
                let firstTask = self.tasksQueue.removeFirst()
                self.isBusy = true
                firstTask({ [weak self] () -> Void in
                    self?.isBusy = false
                    self?.maybeExecuteNextTask()
                })
            }
        }
    }
}
