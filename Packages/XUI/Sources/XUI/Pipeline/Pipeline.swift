public struct Pipeline<Input: Sendable, Output: Sendable>: Sendable {
    public typealias Operation = @Sendable (Input) async throws -> Output

    private let operation: Operation

    public init(_ operation: @escaping Operation) {
        self.operation = operation
    }

    public init<S: PipelineStage>(stage: S)
    where S.Input == Input, S.Output == Output {
        operation = stage.execute
    }

    public func execute(_ input: Input) async throws -> Output {
        try await operation(input)
    }

    public func callAsFunction(_ input: Input) async throws -> Output {
        try await execute(input)
    }
}

public extension Pipeline where Input == Output {
    static var identity: Self {
        Pipeline { $0 }
    }
}
