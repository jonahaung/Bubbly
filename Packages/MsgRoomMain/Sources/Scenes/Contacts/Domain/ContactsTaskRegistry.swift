//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

enum ContactsTaskKey: Hashable {
    case appear
    case refresh
    case syncContacts
    case syncGroups
}

actor ContactsTaskRegistry {
    private var tasks = [ContactsTaskKey: Task<Void, Never>]()

    func run(key: ContactsTaskKey, operation: @escaping @Sendable () async -> Void) {
        tasks[key]?.cancel()
        let task = Task {
            await operation()
        }
        tasks[key] = task
    }

    func cancel(_ key: ContactsTaskKey) {
        tasks[key]?.cancel()
        tasks[key] = nil
    }

    func cancelAll() {
        for task in tasks.values {
            task.cancel()
        }
        tasks.removeAll()
    }
}
