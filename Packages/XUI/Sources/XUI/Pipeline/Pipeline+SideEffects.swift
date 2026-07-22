public extension Pipeline {
    func handleInput(
        _ action: @escaping @Sendable (Input) async throws -> Void
    ) -> Pipeline<Input, Output> {
        Pipeline { input in
            try await action(input)
            return try await execute(input)
        }
    }

    func handleOutput(
        _ action: @escaping @Sendable (Output) async throws -> Void
    ) -> Pipeline<Input, Output> {
        then { output in
            try await action(output)
            return output
        }
    }

    func inspect(
        _ action: @escaping @Sendable (Output) -> Void
    ) -> Pipeline<Input, Output> {
        then { output in
            action(output)
            return output
        }
    }
}
