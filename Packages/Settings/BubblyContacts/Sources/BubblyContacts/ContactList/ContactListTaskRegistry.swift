enum ContactListTaskKey: Hashable {
    case appear
    case refresh
    case syncContacts
    case syncGroups
}

actor ContactListTaskRegistry {
    private var tasks = [ContactListTaskKey: Task<Void, Never>]()

    func run(key: ContactListTaskKey, operation: @escaping @Sendable () async -> Void) {
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
