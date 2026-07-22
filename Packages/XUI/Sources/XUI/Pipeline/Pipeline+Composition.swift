public extension Pipeline {
    func then<S: PipelineStage>(
        _ stage: S
    ) -> Pipeline<Input, S.Output>
    where S.Input == Output {
        then(stage.execute)
    }

    func then<NextOutput: Sendable>(
        _ operation: @escaping @Sendable (Output) async throws -> NextOutput
    ) -> Pipeline<Input, NextOutput> {
        Pipeline<Input, NextOutput> { input in
            let output = try await execute(input)
            return try await operation(output)
        }
    }

    func map<NextOutput: Sendable>(
        _ transform: @escaping @Sendable (Output) throws -> NextOutput
    ) -> Pipeline<Input, NextOutput> {
        then { output in
            try transform(output)
        }
    }

    func asyncMap<NextOutput: Sendable>(
        _ transform: @escaping @Sendable (Output) async throws -> NextOutput
    ) -> Pipeline<Input, NextOutput> {
        then(transform)
    }

    func validate(
        _ validation: @escaping @Sendable (Output) async throws -> Void
    ) -> Pipeline<Input, Output> {
        then { output in
            try await validation(output)
            return output
        }
    }

    func transform(
        if condition: @escaping @Sendable (Output) -> Bool,
        using transform: @escaping @Sendable (Output) async throws -> Output
    ) -> Pipeline<Input, Output> {
        then { output in
            guard condition(output) else {
                return output
            }
            return try await transform(output)
        }
    }
}
