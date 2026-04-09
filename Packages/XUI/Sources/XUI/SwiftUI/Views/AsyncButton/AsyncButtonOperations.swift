//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

public enum AsyncButtonOperation {
    case loading(Task<Void, Error>)
    case completed(Task<Void, Error>, Result<Void, Error>)

    var task: Task<Void, Error> {
        switch self {
        case let .loading(task):
            task
        case let .completed(task, _):
            task
        }
    }
}

extension AsyncButtonOperation: Equatable {
    public static func == (lhs: AsyncButtonOperation, rhs: AsyncButtonOperation) -> Bool {
        if case let .loading(lhsTask) = lhs, case let .loading(rhsTask) = rhs {
            lhsTask == rhsTask
        } else if case let .completed(lhsTask, _) = lhs, case let .completed(rhsTask, _) = rhs {
            lhsTask == rhsTask
        } else {
            false
        }
    }
}
