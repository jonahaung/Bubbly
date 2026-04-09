//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

private protocol Cancelling {
	func cancel()
}

private protocol Awaitable: Sendable {
	func waitForCompletion() async
}

extension Task: Awaitable, Cancelling {
	fileprivate func waitForCompletion() async {
		_ = try? await value
	}
}

public final class AsyncQueue: Sendable {
#if compiler(>=6.0)
	public typealias ThrowingOperation<Success> = @isolated(any) @Sendable () async throws
	-> sending Success
	public typealias Operation<Success> = @isolated(any) @Sendable () async -> sending Success
#else
	public typealias ThrowingOperation<Success: Sendable> = @Sendable () async throws -> Success
	public typealias Operation<Success: Sendable> = @Sendable () async -> Success
#endif

	public typealias ErrorSequence = AsyncStream<Error>

	public struct Attributes: OptionSet, Sendable {
		public let rawValue: UInt64

		public static let concurrent = Attributes(rawValue: 1 << 0)
		public static let publishErrors = Attributes(rawValue: 2 << 0)

		public init(rawValue: UInt64) {
			self.rawValue = rawValue
		}
	}

	private struct QueueEntry {
		let task: any (Awaitable & Cancelling)
		let isBarrier: Bool
		let id: UUID
	}

	private struct ExecutionProperties {
		let dependencies: [any Awaitable]
		let isBarrier: Bool
		let id: UUID
	}

	private let lock = NSLock()
	nonisolated(unsafe)
	private var pendingTasks = [QueueEntry]()
	private let attributes: Attributes
	private let errorContinuation: ErrorSequence.Continuation

	/// An AsyncSequence of all errors thrown from operations.
	///
	/// Errors are published here even if a reference to the operation task is held and awaited.
	/// But, it can still very useful for logging and debugging purposes. This sequence will not
	/// include any `CancellationError`s thrown.
	public let errorSequence: ErrorSequence

	public init(_ attributes: Attributes = .init()) {
		self.attributes = attributes
		lock.name = "AsyncQueue"

		(errorSequence, errorContinuation) = ErrorSequence.makeStream()
	}

	deinit {
		errorContinuation.finish()
		cancel()
	}

	private func completePendingTask(with props: ExecutionProperties) {
		lock.lock()
		defer { lock.unlock() }

		// Silently ignore if not found - might happen if task was cancelled
		if let idx = pendingTasks.firstIndex(where: { $0.id == props.id }) {
			pendingTasks.remove(at: idx)
		}
	}

	private func createTask<Success, Failure>(
		barrier: Bool,
		_ block: (ExecutionProperties) -> Task<
		Success,
		Failure
		>
	) -> Task<Success, Failure> {
		let id = UUID()

		lock.lock()
		defer { lock.unlock() }

		let dependencies: [any Awaitable]

		switch (barrier, attributes.contains(.concurrent)) {
		case (_, false):
			// this is the simple case of a plain ol' serial queue. Everything is a barrier.
			dependencies = pendingTasks.last.flatMap { [$0.task] } ?? []
		case (false, true):
			// we must wait on the most-recently enqueued barrier
			let lastBarrier = pendingTasks.last(where: { $0.isBarrier })

			dependencies = lastBarrier.flatMap { [$0.task] } ?? []
		case (true, true):
			// the trickiest case: wait for *all* tasks until the last barrier

			let idx = pendingTasks.lastIndex(where: { $0.isBarrier }) ?? pendingTasks.startIndex

			dependencies = pendingTasks.suffix(from: idx).map(\.task)
		}

		let props = ExecutionProperties(dependencies: dependencies, isBarrier: barrier, id: id)
		let task = block(props)

		let entry = QueueEntry(task: task, isBarrier: barrier, id: id)

		pendingTasks.append(entry)

		return task
	}

	private func executeOperation<Success>(
		props: ExecutionProperties,
		@_inheritActorContext operation: @escaping ThrowingOperation<
		Success
		>
	) async rethrows -> Success {
		defer {
			completePendingTask(with: props)
		}

		for awaitable in props.dependencies {
			await awaitable.waitForCompletion()
		}

		do {
			return try await withTaskCancellationHandler {
				try await operation()
			} onCancel: { [weak self] in
				self?.completePendingTask(with: props)
			}
		} catch is CancellationError {
			throw CancellationError()
		} catch {
#if compiler(>=5.9)
			if attributes.contains(.publishErrors) {
				errorContinuation.yield(error)
			}
#endif

			throw error
		}
	}
}

public extension AsyncQueue {
	/// Submit a throwing operation to the queue.
	@discardableResult
	func addOperation<Success>(
		priority: TaskPriority? = .userInitiated,
		barrier: Bool = true,
		@_inheritActorContext operation: @escaping ThrowingOperation<
		Success
		>
	)
	-> Task<
		Success,
		Error
	> {
		let asBarrier = barrier || attributes.contains([.concurrent]) == false

		return createTask(barrier: asBarrier) { props in
			Task<Success, Error>(priority: priority) {
				try await executeOperation(props: props, operation: operation)
			}
		}
	}

	/// Submit an operation to the queue.
	@discardableResult
	func addOperation<Success>(
		priority: TaskPriority? = .userInitiated,
		barrier: Bool = true,
		@_inheritActorContext operation: @escaping Operation<Success>
	)
	-> Task<
		Success,
		Never
	> {
		let asBarrier = barrier || attributes.contains([.concurrent]) == false

		return createTask(barrier: asBarrier) { props in
			Task<Success, Never>(priority: priority) {
				await executeOperation(props: props, operation: operation)
			}
		}
	}
}

public extension AsyncQueue {
	/// Submit a throwing barrier operation to the queue.
	@discardableResult
	func addBarrierOperation<Success: Sendable>(
		priority: TaskPriority? = .high,
		@_inheritActorContext operation: @escaping ThrowingOperation<
		Success
		>
	) -> Task<Success, Error> {
		addOperation(priority: priority, barrier: true, operation: operation)
	}

	/// Submit a barrier operation to the queue.
	@discardableResult
	func addBarrierOperation<Success: Sendable>(
		priority: TaskPriority? = .high,
		@_inheritActorContext operation: @escaping Operation<
		Success
		>
	) -> Task<Success, Never> {
		addOperation(priority: priority, barrier: true, operation: operation)
	}
}

public extension AsyncQueue {
	/// Cancel all pending tasks.
	func cancel() {
		lock.lock()
		defer { lock.unlock() }

		pendingTasks.forEach { $0.task.cancel() }
	}
}


public actor AsyncActorQueue {
#if compiler(>=6.0)
	public typealias ThrowingOperation<Success> = @isolated(any) @Sendable () async throws
	-> sending Success
	public typealias Operation<Success> = @isolated(any) @Sendable () async -> sending Success
#else
	public typealias ThrowingOperation<Success: Sendable> = @Sendable () async throws -> Success
	public typealias Operation<Success: Sendable> = @Sendable () async -> Success
#endif

	public typealias ErrorSequence = AsyncStream<Error>

	public struct Attributes: OptionSet, Sendable {
		public let rawValue: UInt64

		public static let concurrent = Attributes(rawValue: 1 << 0)
		public static let publishErrors = Attributes(rawValue: 2 << 0)

		public init(rawValue: UInt64) {
			self.rawValue = rawValue
		}
	}

	private struct QueueEntry {
		let task: any (Awaitable & Cancelling)
		let isBarrier: Bool
		let id: UUID
	}

	private struct ExecutionProperties {
		let dependencies: [any Awaitable]
		let isBarrier: Bool
		let id: UUID
	}

	private var pendingTasks = [QueueEntry]()
	private let attributes: Attributes
	private let errorContinuation: ErrorSequence.Continuation

	/// An AsyncSequence of all errors thrown from operations.
	public let errorSequence: ErrorSequence

	public init(_ attributes: Attributes = .init()) {
		self.attributes = attributes
		(errorSequence, errorContinuation) = ErrorSequence.makeStream()
	}

	deinit {
		errorContinuation.finish()
	}

	private func completePendingTask(with props: ExecutionProperties) {
		if let idx = pendingTasks.firstIndex(where: { $0.id == props.id }) {
			pendingTasks.remove(at: idx)
		}
	}

	private func createTask<Success, Failure>(
		barrier: Bool,
		_ block: (ExecutionProperties) -> Task<Success, Failure>
	) -> Task<Success, Failure> {
		let id = UUID()

		let dependencies: [any Awaitable]

		switch (barrier, attributes.contains(.concurrent)) {
		case (_, false):
			dependencies = pendingTasks.last.flatMap { [$0.task] } ?? []
		case (false, true):
			let lastBarrier = pendingTasks.last(where: { $0.isBarrier })
			dependencies = lastBarrier.flatMap { [$0.task] } ?? []
		case (true, true):
			let idx = pendingTasks.lastIndex(where: { $0.isBarrier }) ?? pendingTasks.startIndex
			dependencies = pendingTasks.suffix(from: idx).map(\.task)
		}

		let props = ExecutionProperties(dependencies: dependencies, isBarrier: barrier, id: id)
		let task = block(props)

		let entry = QueueEntry(task: task, isBarrier: barrier, id: id)
		pendingTasks.append(entry)

		return task
	}

	private func executeOperation<Success>(
		props: ExecutionProperties,
		operation: @escaping ThrowingOperation<Success>
	) async rethrows -> Success {
		defer {
			completePendingTask(with: props)
		}

		for awaitable in props.dependencies {
			await awaitable.waitForCompletion()
		}

		do {
			return try await withTaskCancellationHandler {
				try await operation()
			} onCancel: { [weak self] in
				Task { await self?.completePendingTask(with: props) }
			}
		} catch is CancellationError {
			throw CancellationError()
		} catch {
			if attributes.contains(.publishErrors) {
				errorContinuation.yield(error)
			}
			throw error
		}
	}

	// MARK: - Public API

	@discardableResult
	public func addOperation<Success>(
		priority: TaskPriority? = nil,
		barrier: Bool = true,
		operation: @escaping ThrowingOperation<Success>
	) -> Task<Success, Error> {
		let asBarrier = barrier || attributes.contains([.concurrent]) == false
		return createTask(barrier: asBarrier) { props in
			Task<Success, Error>(priority: priority) {
				try await self.executeOperation(props: props, operation: operation)
			}
		}
	}

	@discardableResult
	public func addOperation<Success>(
		priority: TaskPriority? = nil,
		barrier: Bool = true,
		operation: @escaping Operation<Success>
	) -> Task<Success, Never> {
		let asBarrier = barrier || attributes.contains([.concurrent]) == false
		return createTask(barrier: asBarrier) { props in
			Task<Success, Never>(priority: priority) {
				await self.executeOperation(props: props, operation: operation)
			}
		}
	}

	@discardableResult
	public func addBarrierOperation<Success: Sendable>(
		priority: TaskPriority? = nil,
		operation: @escaping ThrowingOperation<Success>
	) -> Task<Success, Error> {
		addOperation(priority: priority, barrier: true, operation: operation)
	}

	@discardableResult
	public func addBarrierOperation<Success: Sendable>(
		priority: TaskPriority? = nil,
		operation: @escaping Operation<Success>
	) -> Task<Success, Never> {
		addOperation(priority: priority, barrier: true, operation: operation)
	}

	public func cancel() {
		for entry in pendingTasks {
			entry.task.cancel()
		}
		pendingTasks.removeAll()
	}
}
