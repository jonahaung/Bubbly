public enum PipelineTimeoutError: Error, Equatable, Sendable {
    case invalidDuration
    case timedOut
}

public extension Pipeline {
    func timeout(after duration: Duration) -> Pipeline<Input, Output> {
        Pipeline { input in
            guard duration > .zero else {
                throw PipelineTimeoutError.invalidDuration
            }

            return try await withThrowingTaskGroup(of: Output.self) { group in
                group.addTask {
                    try await execute(input)
                }
                group.addTask {
                    try await Task.sleep(for: duration)
                    throw PipelineTimeoutError.timedOut
                }

                defer {
                    group.cancelAll()
                }

                guard let output = try await group.next() else {
                    throw PipelineTimeoutError.timedOut
                }
                return output
            }
        }
    }
}
