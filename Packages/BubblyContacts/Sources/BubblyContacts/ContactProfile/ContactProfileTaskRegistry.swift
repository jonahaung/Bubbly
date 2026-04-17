enum ContactProfileTaskKey: Hashable {
    case appear
    case refresh
    case updateContact
    case updateProperties
    case deleteMessages
}

actor ContactProfileTaskRegistry {
    private var tasks = [ContactProfileTaskKey: Task<Void, Never>]()

    func run(key: ContactProfileTaskKey, operation: @escaping @Sendable () async -> Void) {
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
