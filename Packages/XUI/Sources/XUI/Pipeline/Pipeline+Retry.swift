public enum PipelineRetryError: Error, Equatable, Sendable {
    case invalidRetryCount
    case executionFailed
}

public extension Pipeline {
    func retry(_ count: Int) -> Pipeline<Input, Output> {
        Pipeline { input in
            guard count >= 0 else {
                throw PipelineRetryError.invalidRetryCount
            }

            var lastError: (any Error)?

            for _ in 0...count {
                try Task.checkCancellation()

                do {
                    return try await execute(input)
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    lastError = error
                }
            }

            throw lastError ?? PipelineRetryError.executionFailed
        }
    }
}
