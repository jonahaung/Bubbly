public extension Pipeline {
    func recover(
        _ handler: @escaping @Sendable (any Error) async throws -> Output
    ) -> Pipeline<Input, Output> {
        Pipeline { input in
            do {
                return try await execute(input)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                return try await handler(error)
            }
        }
    }

    func replaceError(with fallback: Output) -> Pipeline<Input, Output> {
        recover { _ in fallback }
    }

    func handleError(
        _ action: @escaping @Sendable (any Error) async -> Void
    ) -> Pipeline<Input, Output> {
        Pipeline { input in
            do {
                return try await execute(input)
            } catch {
                await action(error)
                throw error
            }
        }
    }
}
