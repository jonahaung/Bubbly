// © 2026 Aung Ko Min

// MARK: - PlaygroundTaskKey

enum PlaygroundTaskKey: Hashable {
    case appear
    case refresh
    case submit
}

// MARK: - PlaygroundTaskRegistry

actor PlaygroundTaskRegistry {
    private var tasks: [PlaygroundTaskKey: Task<Void, Never>] = [:]

    func run(key: PlaygroundTaskKey, operation: @escaping @Sendable () async -> Void) {
        tasks[key]?.cancel()
        let task = Task {
            await operation()
        }
        tasks[key] = task
    }

    func cancelAll() {
        for task in tasks.values {
            task.cancel()
        }
        tasks.removeAll()
    }
}
