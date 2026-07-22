public struct AnyPipelineStage<Input: Sendable, Output: Sendable>: PipelineStage {
    private let operation: @Sendable (Input) async throws -> Output

    public init<S: PipelineStage>(_ stage: S)
    where S.Input == Input, S.Output == Output {
        operation = stage.execute
    }

    public init(
        _ operation: @escaping @Sendable (Input) async throws -> Output
    ) {
        self.operation = operation
    }

    public func execute(_ input: Input) async throws -> Output {
        try await operation(input)
    }
}

public extension Pipeline {
    func eraseToAnyStage() -> AnyPipelineStage<Input, Output> {
        AnyPipelineStage(execute)
    }
}
