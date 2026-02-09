//
//  AttachmentFetcher.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 18/12/25.
//

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
	private var pendingQueue: [Attachment] = []
	private var waiters: [Attachment: [CheckedContinuation<AttachmentData, Error>]] = [:]

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
		for attachment in pendingQueue where !visible.contains(attachment) {
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
		tasks.isEmpty && pendingQueue.isEmpty
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

		if tasks[attachment] != nil || pendingQueue.contains(attachment) {
			return false
		}

		taskPriorities[attachment] = intent.priority

		if hasCapacity {
			startTask(for: attachment)
			return true
		} else {
			pendingQueue.append(attachment)
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

		if pendingQueue.contains(attachment) {
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
			pendingQueue.append(attachment)
			return try await waitForPending(
				attachment: attachment,
				timeout: timeout
			)
		}
	}

	// MARK: - Cancellation

	public func cancel(_ attachment: Attachment) {
		pendingQueue.removeAll { $0 == attachment }
		tasks.removeValue(forKey: attachment)?.cancel()
		completions[attachment] = nil
		taskPriorities[attachment] = nil

		if let continuations = waiters.removeValue(forKey: attachment) {
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
		taskPriorities.removeAll()
		completions.removeAll()

		for continuations in waiters.values {
			for cont in continuations {
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
		pendingQueue.contains(attachment)
	}

	public var activeCount: Int {
		inFlightCount
	}

	public var pendingCount: Int {
		pendingQueue.count
	}

	// MARK: - Scheduling

	public func promote(_ attachment: Attachment) {
		guard let idx = pendingQueue.firstIndex(of: attachment) else { return }
		pendingQueue.remove(at: idx)
		pendingQueue.insert(attachment, at: 0)

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

		if let continuations = waiters.removeValue(forKey: attachment) {
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
		while hasCapacity, !pendingQueue.isEmpty {
			let next = pendingQueue.removeFirst()
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

		return try await withCheckedThrowingContinuation {
			waiters[attachment, default: []].append($0)
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
			let value = try await group.next()!
			group.cancelAll()
			return value
		}
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
