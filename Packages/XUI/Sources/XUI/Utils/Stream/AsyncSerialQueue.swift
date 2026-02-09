//
//  AsyncSerialQueue.swift
//  XUI
//
//  Created by Aung Ko Min on 31/10/25.
//

import Foundation

public actor AsyncSerialQueue {
	public typealias Operation = @Sendable () async -> Void
	public actor QueueTask {
		private var cancelled = false
		private let operation: Operation

		init(operation: @escaping Operation) {
			self.operation = operation
		}

		public func cancel() {
			cancelled = true
		}

		func run() async throws {
			guard !cancelled else { return }
			await operation()
		}
	}

	private typealias Stream = AsyncStream<QueueTask>

	private let continuation: Stream.Continuation
	private var processingTask: Task<Void, Never>?
	private let onError: (@Sendable (any Error) -> Void)?

	public init(onError: (@Sendable (any Error) -> Void)? = nil) {
		self.onError = onError
		let (stream, continuation) = Stream.makeStream()
		self.continuation = continuation
		processingTask = Task { [onError] in
			for await item in stream {
				do {
					try await item.run()
				} catch {
					onError?(error)
				}
			}
		}
	}

	deinit {
		continuation.finish()
		processingTask?.cancel()
	}

	public func finish() {
		continuation.finish()
		processingTask?.cancel()
	}

	@discardableResult
	private func enqueue(_ operation: @escaping Operation) -> QueueTask {
		let queueTask = QueueTask(operation: operation)
		continuation.yield(queueTask)
		return queueTask
	}

	@discardableResult
	public func addOperation<Failure: Error>(_ operation: @Sendable @escaping () async throws(Failure)
		-> Void) -> QueueTask
	{
		enqueue {
			do {
				try await operation()
			} catch {
				// Swallow, log, or route the error somewhere appropriate.
				// print("AsyncSerialQueue operation failed: \(error)")
			}
		}
	}
}
