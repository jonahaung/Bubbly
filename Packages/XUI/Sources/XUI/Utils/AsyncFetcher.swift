import Foundation

public actor AsyncFetcher<T: Sendable> {
	public typealias ID = String
	public typealias Fetch = @Sendable (ID) async throws -> T
	public typealias Completion = @Sendable (Result<T, Error>) -> Void

	// MARK: - Private Properties

	private let fetch: Fetch
	private let maxConcurrent: Int

	/// Active tasks keyed by id
	private var tasks: [ID: Task<T, Error>] = [:]
	/// Completion handlers to call when task finishes
	private var completions: [ID: [Completion]] = [:]

	/// Pending queue (FIFO)
	private var pendingQueue: [ID] = []

	/// Waiters who are awaiting a pending task to start
	private var waiters: [ID: [CheckedContinuation<T, Error>]] = [:]

	private var inFlightCount: Int {
		tasks.count
	}

	private var hasCapacity: Bool {
		inFlightCount < maxConcurrent
	}

	// MARK: - Initialization

	public init(maxConcurrent: Int = 10, fetch: @escaping Fetch) {
		precondition(maxConcurrent > 0, "maxConcurrent must be > 0")
		self.maxConcurrent = maxConcurrent
		self.fetch = fetch
	}

	deinit {
		// Hop to the actor to perform cleanup
		Task { [weak self] in
			await self?.cancelAll()
		}
	}

	// MARK: - Public Interface

	/// Prefetch an id. Returns true if started immediately, false if queued or already in-flight.
	@discardableResult
	public func prefetch(_ id: ID, completion: Completion? = nil) -> Bool {
		// Add completion handler if provided
		if let completion {
			completions[id, default: []].append(completion)
		}

		// If already fetching, attach completion and return false
		if tasks[id] != nil {
			return false
		}

		// If already pending, attach completion and return false
		if pendingQueue.contains(id) {
			return false
		}

		// Start immediately if we have capacity
		if hasCapacity {
			startTask(for: id)
			return true
		} else {
			// Enqueue (FIFO)
			pendingQueue.append(id)
			return false
		}
	}

	/// Fetch a value, waiting for it if necessary
	public func fetch(_ id: ID) async throws -> T {
		log("fetching attachment with id: \(id)")
		// If already fetching, return its value
		if let existingTask = tasks[id] {
			return try await existingTask.value
		}

		// If pending, await until it starts (no busy-wait)
		if pendingQueue.contains(id) {
			return try await waitForPending(id: id)
		}

		// Otherwise create and start a new task immediately if capacity, or enqueue & wait
		if hasCapacity {
			startTask(for: id)
			guard let task = tasks[id] else {
				// Unexpected - treat as cancellation
				throw CancellationError()
			}
			return try await task.value
		} else {
			// Avoid duplicate pending entries for the same id
			if !pendingQueue.contains(id) {
				pendingQueue.append(id)
			}
			return try await waitForPending(id: id)
		}
	}

	public func cancel(_ id: ID) {
		// Remove from pending queue (if present)
		if let idx = pendingQueue.firstIndex(of: id) {
			pendingQueue.remove(at: idx)
		}

		// Cancel and remove task if present
		if let task = tasks.removeValue(forKey: id) {
			task.cancel()
		}

		// Clear completions
		completions[id] = nil

		// Resume any waiters with cancellation
		if let continuations = waiters.removeValue(forKey: id) {
			for cont in continuations {
				cont.resume(throwing: CancellationError())
			}
		}

		// Schedule next pending task
		scheduleIfNeeded()
	}

	public func cancelAll() {
		// Clear pending and resume all waiters
		let pendingIDs = pendingQueue
		pendingQueue.removeAll()
		for id in pendingIDs {
			if let continuations = waiters.removeValue(forKey: id) {
				for cont in continuations {
					cont.resume(throwing: CancellationError())
				}
			}
		}

		// Cancel all in-flight tasks
		for (_, task) in tasks {
			task.cancel()
		}
		tasks.removeAll()

		// Clear completions
		completions.removeAll()
	}

	public func isFetching(_ id: ID) -> Bool {
		tasks[id] != nil
	}

	public func isPending(_ id: ID) -> Bool {
		pendingQueue.contains(id)
	}

	public var activeCount: Int {
		inFlightCount
	}

	public var pendingCount: Int {
		pendingQueue.count
	}

	// MARK: - Private Methods

	private func startTask(for id: ID) {
		// If already started by racing caller, do nothing
		if tasks[id] != nil { return }

		// Create task and register it
		let task = createTask(for: id)
		tasks[id] = task

		// Resume any waiters waiting for the task to start.
		if let continuations = waiters.removeValue(forKey: id) {
			for cont in continuations {
				// Resume each waiter by awaiting the task's result and resuming appropriately.
				Task {
					let result = await task.result
					switch result {
					case let .success(value):
						cont.resume(returning: value)
					case let .failure(error):
						cont.resume(throwing: error)
					}
				}
			}
		}
	}

	private func createTask(for id: ID) -> Task<T, Error> {
		// Use Task (not detached) so the task inherits the cooperative cancellation model.
		Task { [fetch] in
			do {
				let value = try await fetch(id)
				// Notify completions (nonisolated helper will forward to actor)
				handleCompletion(id: id, result: .success(value))
				return value
			} catch {
				handleCompletion(id: id, result: .failure(error))
				throw error
			}
		}
	}

	private func scheduleIfNeeded() {
		// Start as many queued tasks as we have capacity (FIFO)
		while hasCapacity, !pendingQueue.isEmpty {
			let nextID = pendingQueue.removeFirst()
			// If it started already (race), skip
			if tasks[nextID] == nil {
				startTask(for: nextID)
			}
		}
	}

	private func waitForPending(id: ID) async throws -> T {
		// If task already started while awaiting, return it.
		if let task = tasks[id] {
			return try await task.value
		}

		return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<
			T,
			Error
		>) in
			waiters[id, default: []].append(continuation)
			// If the id was removed from pending before it starts (e.g. cancelled),
			// the cancellation path will resume the continuation.
		}
	}

	private nonisolated func handleCompletion(id: ID, result: Result<T, Error>) {
		// Forward back to actor isolation to finalize state changes.
		Task { await self.finalizeFetch(id: id, result: result) }
	}

	private func finalizeFetch(id: ID, result: Result<T, Error>) {
		// Remove the task entry (if present)
		tasks.removeValue(forKey: id)

		// Execute completion handlers off the actor so handlers can't block the actor.
		if let handlers = completions.removeValue(forKey: id), !handlers.isEmpty {
			Task.detached(priority: .utility) {
				for handler in handlers {
					handler(result)
				}
			}
		}

		// Schedule next pending task
		scheduleIfNeeded()
	}
}

// MARK: - Error Types

public extension AsyncFetcher {
	struct TimeoutError: Error, LocalizedError {
		public var errorDescription: String? {
			"Operation timed out waiting for pending task to start"
		}
	}
}

// MARK: - Convenience Extensions

public extension AsyncFetcher {
	/// Prefetch multiple IDs
	func prefetch(_ ids: [ID]) {
		for id in ids {
			prefetch(id)
		}
	}

	func cancelPrefetch(_ ids: [ID]) {
		for id in ids {
			cancel(id)
		}
	}

	/// Get current state for an ID
	enum FetchState: Sendable {
		case fetching, pending, idle
	}

	func state(for id: ID) -> FetchState {
		if isFetching(id) { return .fetching }
		if isPending(id) { return .pending }
		return .idle
	}
}
