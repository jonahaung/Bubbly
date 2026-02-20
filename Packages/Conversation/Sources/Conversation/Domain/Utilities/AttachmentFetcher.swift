import Core
import Database
import Foundation
import ImageLoader
import Services
import SwiftUI
import VideoLoader
import WebKit
import XUI

// MARK: - Scroll Intent

public enum FetchIntent: Sendable {
	case prefetch
	case visible
	case userInitiated
}

private extension FetchIntent {
	var priority: TaskPriority {
		switch self {
		case .prefetch: .background
		case .visible: .userInitiated
		case .userInitiated: .high
		}
	}
}

// MARK: - AttachmentFetcher

public actor AttachmentFetcher {
	public static let shared = AttachmentFetcher()

	public typealias Fetch = @Sendable (Attachment) async throws -> AttachmentData
	public typealias Completion = @Sendable (Result<AttachmentData, Error>) -> Void

	private let api = AttachmentDataAPI()

	private var maxConcurrent: Int

	private var tasks: [Attachment: Task<AttachmentData, Error>] = [:]
	private var taskPriorities: [Attachment: TaskPriority] = [:]
	private var completions: [Attachment: [Completion]] = [:]
	private var pendingQueue = Deque<Attachment>()
	private var pendingSet = Set<Attachment>()
	private var waiters: [Attachment: [UUID: CheckedContinuation<AttachmentData, Error>]] = [:]

	private var inFlightCount: Int {
		tasks.count
	}

	private var hasCapacity: Bool {
		inFlightCount < maxConcurrent
	}

	// MARK: - Init

	public init(maxConcurrent: Int = 10) {
		precondition(maxConcurrent > 0, "maxConcurrent must be > 0")
		self.maxConcurrent = maxConcurrent
	}

	// MARK: - Scroll Tuning

	public func setScrolling(_ isScrolling: Bool) {
		setMaxConcurrent(isScrolling ? 4 : 10)
	}

	public func markVisible(_ attachment: Attachment) {
		promote(attachment)
	}

	public func cancelPrefetchOffscreen(keep visible: Set<Attachment>) {
		for attachment in pendingSet where !visible.contains(attachment) {
			cancel(attachment)
		}
	}

	// MARK: - Concurrency

	public func setMaxConcurrent(_ newValue: Int) {
		precondition(newValue > 0, "maxConcurrent must be > 0")
		maxConcurrent = newValue
		scheduleIfNeeded()
	}

	public var isIdle: Bool {
		tasks.isEmpty && pendingSet.isEmpty
	}

	// MARK: - Prefetch / Fetch

	@discardableResult
	public func prefetch(_ attachment: Attachment,
	                     intent: FetchIntent = .prefetch,
	                     completion: Completion? = nil) -> Bool
	{
		if let completion {
			completions[attachment, default: []].append(completion)
		}

		if tasks[attachment] != nil || pendingSet.contains(attachment) {
			return false
		}

		taskPriorities[attachment] = intent.priority

		if hasCapacity {
			startTask(for: attachment)
			return true
		} else {
			enqueuePending(attachment)
			return false
		}
	}

	public func fetch(_ attachment: Attachment,
	                  intent: FetchIntent,
	                  timeout: Duration? = .seconds(10)) async throws -> AttachmentData
	{
		if let existingTask = tasks[attachment] {
			return try await awaitWithOptionalTimeout(
				task: existingTask,
				timeout: timeout
			)
		}

		if pendingSet.contains(attachment) {
			return try await waitForPending(
				attachment: attachment,
				timeout: timeout
			)
		}

		taskPriorities[attachment] = intent.priority

		if hasCapacity {
			startTask(for: attachment)
			guard let task = tasks[attachment] else {
				throw CancellationError()
			}
			return try await awaitWithOptionalTimeout(
				task: task,
				timeout: timeout
			)
		} else {
			enqueuePending(attachment)
			return try await waitForPending(
				attachment: attachment,
				timeout: timeout
			)
		}
	}

	// MARK: - Cancellation

	public func cancel(_ attachment: Attachment) {
		removePending(attachment)
		tasks.removeValue(forKey: attachment)?.cancel()
		completions[attachment] = nil
		taskPriorities[attachment] = nil

		if let continuations = waiters.removeValue(forKey: attachment)?.values {
			for cont in continuations {
				cont.resume(throwing: CancellationError())
			}
		}
		scheduleIfNeeded()
	}

	public func cancelAll() {
		for task in tasks.values {
			task.cancel()
		}
		tasks.removeAll()
		pendingQueue.removeAll()
		pendingSet.removeAll()
		taskPriorities.removeAll()
		completions.removeAll()

		for continuations in waiters.values {
			for cont in continuations.values {
				cont.resume(throwing: CancellationError())
			}
		}
		waiters.removeAll()
	}

	// MARK: - Introspection

	public func isFetching(_ attachment: Attachment) -> Bool {
		tasks[attachment] != nil
	}

	public func isPending(_ attachment: Attachment) -> Bool {
		pendingSet.contains(attachment)
	}

	public var activeCount: Int {
		inFlightCount
	}

	public var pendingCount: Int {
		pendingSet.count
	}

	// MARK: - Scheduling

	public func promote(_ attachment: Attachment) {
		guard pendingSet.contains(attachment) else { return }
		var reordered = Deque<Attachment>(pendingQueue.count)
		reordered.enqueue(attachment)
		for candidate in pendingQueue where candidate != attachment {
			reordered.enqueue(candidate)
		}
		pendingQueue = reordered

		if let current = taskPriorities[attachment], current < .userInitiated {
			taskPriorities[attachment] = .userInitiated
		}
		scheduleIfNeeded()
	}

	private func startTask(for attachment: Attachment) {
		guard tasks[attachment] == nil else { return }

		let task = createTask(
			for: attachment,
			priority: taskPriorities[attachment] ?? .background
		)
		tasks[attachment] = task

			if let continuations = waiters.removeValue(forKey: attachment)?.values {
				for cont in continuations {
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

	private func createTask(for attachment: Attachment,
	                        priority: TaskPriority) -> Task<AttachmentData, Error>
	{
		Task(priority: priority) {
			do {
				let data = try await api.fetchAttachmentData(for: attachment)
				finalizeFetch(
					attachment: attachment,
					result: .success(data)
				)
				return data
			} catch {
				finalizeFetch(
					attachment: attachment,
					result: .failure(error)
				)
				throw error
			}
		}
	}

	private func scheduleIfNeeded() {
		while hasCapacity, !pendingSet.isEmpty {
			guard let next = popPending() else { break }
			if tasks[next] == nil {
				startTask(for: next)
			}
		}
	}

	// MARK: - Waiting / Timeout

	private func waitForPending(attachment: Attachment,
	                            timeout: Duration?) async throws -> AttachmentData
	{
		if let task = tasks[attachment] {
			return try await awaitWithOptionalTimeout(
				task: task,
				timeout: timeout
			)
		}

		guard let timeout else {
			return try await waitForPendingWithoutTimeout(attachment: attachment)
		}

		return try await withThrowingTaskGroup(of: AttachmentData.self) { group in
			group.addTask { try await self.waitForPendingWithoutTimeout(attachment: attachment) }
			group.addTask {
				try await Task.sleep(for: timeout)
				throw TimeoutError()
			}
			guard let value = try await group.next() else {
				group.cancelAll()
				throw CancellationError()
			}
			group.cancelAll()
			return value
		}
	}

	private func waitForPendingWithoutTimeout(attachment: Attachment) async throws -> AttachmentData {
		let waiterID = UUID()
		return try await withTaskCancellationHandler {
			try await withCheckedThrowingContinuation { continuation in
				waiters[attachment, default: [:]][waiterID] = continuation
			}
		} onCancel: {
			Task { [weak self] in
				await self?.cancelWaiter(attachment: attachment, waiterID: waiterID)
			}
		}
	}

	private func awaitWithOptionalTimeout(task: Task<AttachmentData, Error>,
	                                      timeout: Duration?) async throws -> AttachmentData
	{
		guard let timeout else {
			return try await task.value
		}

		return try await withThrowingTaskGroup(of: AttachmentData.self) { group in
			group.addTask { try await task.value }
			group.addTask {
				try await Task.sleep(for: timeout)
				throw TimeoutError()
			}
			guard let value = try await group.next() else {
				group.cancelAll()
				throw CancellationError()
			}
			group.cancelAll()
			return value
		}
	}

	private func cancelWaiter(attachment: Attachment, waiterID: UUID) {
		guard var attachmentWaiters = waiters[attachment] else { return }
		guard let continuation = attachmentWaiters.removeValue(forKey: waiterID) else { return }
		if attachmentWaiters.isEmpty {
			waiters[attachment] = nil
		} else {
			waiters[attachment] = attachmentWaiters
		}
		continuation.resume(throwing: CancellationError())
	}

	private func enqueuePending(_ attachment: Attachment) {
		guard !pendingSet.contains(attachment) else { return }
		pendingSet.insert(attachment)
		pendingQueue.enqueue(attachment)
	}

	private func popPending() -> Attachment? {
		while let next = pendingQueue.dequeue() {
			if pendingSet.remove(next) != nil {
				return next
			}
		}
		return nil
	}

	private func removePending(_ attachment: Attachment) {
		guard pendingSet.remove(attachment) != nil else { return }
		var rebuilt = Deque<Attachment>(pendingQueue.count)
		for candidate in pendingQueue where pendingSet.contains(candidate) {
			rebuilt.enqueue(candidate)
		}
		pendingQueue = rebuilt
	}

	// MARK: - Completion

	private func finalizeFetch(attachment: Attachment,
	                           result: Result<AttachmentData, Error>)
	{
		tasks.removeValue(forKey: attachment)
		taskPriorities[attachment] = nil

		if let handlers = completions.removeValue(forKey: attachment) {
			Task(priority: .utility) {
				for handler in handlers {
					handler(result)
				}
			}
		}
		scheduleIfNeeded()
	}
}

// MARK: - Errors

public extension AttachmentFetcher {
	struct TimeoutError: Error, LocalizedError {
		public var errorDescription: String? {
			"Operation timed out waiting for pending task to start"
		}
	}
}

// MARK: - Convenience APIs

public extension AttachmentFetcher {
	func prefetch(_ attachments: [Attachment],
	              intent: FetchIntent = .prefetch)
	{
		for attachment in attachments {
			prefetch(attachment, intent: intent)
		}
	}

	enum FetchState: Sendable {
		case fetching
		case pending
		case idle
	}

	func state(for attachment: Attachment) -> FetchState {
		if isFetching(attachment) { return .fetching }
		if isPending(attachment) { return .pending }
		return .idle
	}
}
