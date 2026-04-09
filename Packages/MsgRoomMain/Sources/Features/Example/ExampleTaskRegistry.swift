//
//  Created by Aung Ko Min on 9/4/26.
//

enum ExampleTaskKey: Hashable {
    case appear
    case refresh
    case submit
}

actor ExampleTaskRegistry {
    private var tasks = [ExampleTaskKey: Task<Void, Never>]()

    func run(key: ExampleTaskKey, operation: @escaping @Sendable () async -> Void) {
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
