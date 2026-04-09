// © 2026 Aung Ko Min

#if os(iOS)
//
    // Copyright © 2026 Aung Ko Min. All rights reserved.
//

    import Database
    import Foundation
    import Services
    import XUI

    public enum FetchIntent: Sendable {
        case prefetch
        case visible
        case userInitiated
    }

    fileprivate extension FetchIntent {
        var priority: TaskPriority {
            switch self {
            case .prefetch:
                .background
            case .visible:
                .userInitiated
            case .userInitiated:
                .high
            }
        }
    }

    public actor AttachmentFetcher {
        // MARK: Lifecycle

        public init(maxConcurrent: Int = 10) {
            precondition(maxConcurrent > 0, "maxConcurrent must be > 0")
            self.maxConcurrent = maxConcurrent
            api = AttachmentDataAPI()
        }

        // MARK: Public

        public typealias Completion = @Sendable (Result<AttachmentData, Error>) -> Void

        public var isIdle: Bool {
            tasks.isEmpty && pendingSet.isEmpty
        }

        public var activeCount: Int {
            inFlightCount
        }

        public var pendingCount: Int {
            pendingSet.count
        }

        public func setScrolling(_ isScrolling: Bool) {
            setMaxConcurrent(isScrolling ? 4 : 10)
        }

        public func markVisible(_ attachment: Attachment) {
            let key = key(for: attachment)
            attachmentsByKey[key] = attachment
            promote(key)
        }

        public func cancelPrefetchOffscreen(keep visible: Set<Attachment>) {
            let visibleKeys = Set(visible.map(key(for:)))
            let offscreen = pendingSet.filter { visibleKeys.contains($0) == false }
            for key in offscreen {
                cancel(key)
            }
        }

        public func setMaxConcurrent(_ newValue: Int) {
            precondition(newValue > 0, "maxConcurrent must be > 0")
            maxConcurrent = newValue
            scheduleIfNeeded()
        }

        @discardableResult
        public func prefetch(
            _ attachment: Attachment,
            intent: FetchIntent = .prefetch,
            completion: Completion? = nil,
        ) -> Bool {
            let key = key(for: attachment)
            attachmentsByKey[key] = attachment
            if let completion {
                completions[key, default: []].append(completion)
            }

            if tasks[key] != nil || pendingSet.contains(key) {
                return false
            }

            taskPriorities[key] = intent.priority
            if hasCapacity {
                startTask(for: key)
                return true
            }

            enqueuePending(key)
            return false
        }

        public func fetch(
            _ attachment: Attachment,
            intent: FetchIntent,
            timeout: Duration? = .seconds(10),
        ) async throws -> AttachmentData {
            let key = key(for: attachment)
            attachmentsByKey[key] = attachment

            if let existingTask = tasks[key] {
                return try await awaitWithOptionalTimeout(task: existingTask, timeout: timeout)
            }

            if pendingSet.contains(key) {
                return try await waitForPending(key: key, timeout: timeout)
            }

            taskPriorities[key] = intent.priority
            if hasCapacity {
                startTask(for: key)
                guard let task = tasks[key] else {
                    throw CancellationError()
                }

                return try await awaitWithOptionalTimeout(task: task, timeout: timeout)
            }

            enqueuePending(key)
            return try await waitForPending(key: key, timeout: timeout)
        }

        public func cancel(_ attachment: Attachment) {
            cancel(key(for: attachment))
        }

        public func cancelAll() {
            for task in tasks.values {
                task.cancel()
            }
            tasks.removeAll(keepingCapacity: true)
            taskPriorities.removeAll(keepingCapacity: true)
            completions.removeAll(keepingCapacity: true)
            pendingQueue.removeAll(keepingCapacity: true)
            pendingSet.removeAll(keepingCapacity: true)
            attachmentsByKey.removeAll(keepingCapacity: true)

            for continuations in waiters.values {
                for continuation in continuations.values {
                    continuation.resume(throwing: CancellationError())
                }
            }
            waiters.removeAll(keepingCapacity: true)
        }

        public func isFetching(_ attachment: Attachment) -> Bool {
            tasks[key(for: attachment)] != nil
        }

        public func isPending(_ attachment: Attachment) -> Bool {
            pendingSet.contains(key(for: attachment))
        }

        public func promote(_ attachment: Attachment) {
            let key = key(for: attachment)
            attachmentsByKey[key] = attachment
            promote(key)
        }

        // MARK: Private

        private struct QueueKey: Hashable {
            let uid: String
        }

        private let api: AttachmentDataAPI
        private var maxConcurrent: Int

        private var attachmentsByKey: [QueueKey: Attachment] = [:]
        private var tasks: [QueueKey: Task<AttachmentData, Error>] = [:]
        private var taskPriorities: [QueueKey: TaskPriority] = [:]
        private var completions: [QueueKey: [Completion]] = [:]
        private var pendingQueue: Deque<QueueKey> = .init()
        private var pendingSet: Set<QueueKey> = []
        private var waiters: [QueueKey: [UUID: CheckedContinuation<AttachmentData, Error>]] = [:]

        private var inFlightCount: Int {
            tasks.count
        }

        private var hasCapacity: Bool {
            inFlightCount < maxConcurrent
        }

        private func promote(_ key: QueueKey) {
            guard pendingSet.contains(key) else {
                return
            }

            var reordered = Deque<QueueKey>(pendingQueue.count)
            reordered.enqueue(key)
            for candidate in pendingQueue where candidate != key {
                reordered.enqueue(candidate)
            }
            pendingQueue = reordered

            if let current = taskPriorities[key], current < .userInitiated {
                taskPriorities[key] = .userInitiated
            }
            scheduleIfNeeded()
        }

        private func startTask(for key: QueueKey) {
            guard tasks[key] == nil else {
                return
            }

            guard let attachment = attachmentsByKey[key] else {
                clearKeyState(key)
                return
            }

            let priority = taskPriorities[key] ?? .background
            tasks[key] = createTask(for: key, attachment: attachment, priority: priority)
        }

        private func createTask(
            for key: QueueKey,
            attachment: Attachment,
            priority: TaskPriority,
        ) -> Task<AttachmentData, Error> {
            Task(priority: priority) { [api] in
                do {
                    let data = try await api.fetchAttachmentData(for: attachment)
                    self.finalizeFetch(key: key, result: .success(data))
                    return data
                } catch {
                    self.finalizeFetch(key: key, result: .failure(error))
                    throw error
                }
            }
        }

        private func scheduleIfNeeded() {
            while hasCapacity, let next = popPending() {
                startTask(for: next)
            }
        }

        private func waitForPending(key: QueueKey,
                                    timeout: Duration?) async throws -> AttachmentData
        {
            if let task = tasks[key] {
                return try await awaitWithOptionalTimeout(task: task, timeout: timeout)
            }

            guard pendingSet.contains(key) else {
                throw CancellationError()
            }

            guard let timeout else {
                return try await waitForPendingWithoutTimeout(key: key)
            }

            return try await withThrowingTaskGroup(of: AttachmentData.self) { group in
                group.addTask { try await self.waitForPendingWithoutTimeout(key: key) }
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

        private func waitForPendingWithoutTimeout(key: QueueKey) async throws -> AttachmentData {
            let waiterID = UUID()
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    waiters[key, default: [:]][waiterID] = continuation
                    scheduleIfNeeded()
                }
            } onCancel: {
                Task {
                    await self.cancelWaiter(key: key, waiterID: waiterID)
                }
            }
        }

        private func awaitWithOptionalTimeout(
            task: Task<AttachmentData, Error>,
            timeout: Duration?,
        ) async throws -> AttachmentData {
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

        private func cancelWaiter(key: QueueKey, waiterID: UUID) {
            guard var attachmentWaiters = waiters[key] else {
                return
            }

            guard let continuation = attachmentWaiters.removeValue(forKey: waiterID) else {
                return
            }

            if attachmentWaiters.isEmpty {
                waiters[key] = nil
            } else {
                waiters[key] = attachmentWaiters
            }
            continuation.resume(throwing: CancellationError())
        }

        private func enqueuePending(_ key: QueueKey) {
            guard pendingSet.contains(key) == false else {
                return
            }

            pendingSet.insert(key)
            pendingQueue.enqueue(key)
        }

        private func popPending() -> QueueKey? {
            while let next = pendingQueue.dequeue() {
                if pendingSet.remove(next) != nil {
                    return next
                }
            }
            return nil
        }

        private func removePending(_ key: QueueKey) {
            guard pendingSet.remove(key) != nil else {
                return
            }

            var rebuilt = Deque<QueueKey>(pendingQueue.count)
            for candidate in pendingQueue where pendingSet.contains(candidate) {
                rebuilt.enqueue(candidate)
            }
            pendingQueue = rebuilt
        }

        private func finalizeFetch(key: QueueKey, result: Result<AttachmentData, Error>) {
            tasks[key] = nil
            taskPriorities[key] = nil

            if let continuations = waiters.removeValue(forKey: key)?.values {
                for continuation in continuations {
                    switch result {
                    case let .success(data):
                        continuation.resume(returning: data)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
            }

            if let handlers = completions.removeValue(forKey: key) {
                Task(priority: .utility) {
                    for handler in handlers {
                        handler(result)
                    }
                }
            }

            scheduleIfNeeded()
        }

        private func cancel(_ key: QueueKey) {
            removePending(key)
            if let task = tasks.removeValue(forKey: key) {
                task.cancel()
            }
            taskPriorities[key] = nil

            if let continuations = waiters.removeValue(forKey: key)?.values {
                for continuation in continuations {
                    continuation.resume(throwing: CancellationError())
                }
            }

            if let handlers = completions.removeValue(forKey: key) {
                let result = Result<AttachmentData, Error>.failure(CancellationError())
                Task(priority: .utility) {
                    for handler in handlers {
                        handler(result)
                    }
                }
            }

            clearKeyState(key)
            scheduleIfNeeded()
        }

        private func clearKeyState(_ key: QueueKey) {
            attachmentsByKey[key] = nil
            pendingSet.remove(key)
        }

        private func key(for attachment: Attachment) -> QueueKey {
            .init(uid: attachment.uid)
        }
    }

    public extension AttachmentFetcher {
        struct TimeoutError: Error, LocalizedError {
            public var errorDescription: String? {
                "Operation timed out waiting for pending task to start"
            }
        }
    }

    public extension AttachmentFetcher {
        func prefetch(_ attachments: [Attachment], intent: FetchIntent = .prefetch) {
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
            if isFetching(attachment) {
                return .fetching
            }
            if isPending(attachment) {
                return .pending
            }
            return .idle
        }
    }

#endif
