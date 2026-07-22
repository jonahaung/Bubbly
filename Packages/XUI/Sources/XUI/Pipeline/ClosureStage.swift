public struct ClosureStage<Input: Sendable, Output: Sendable>: PipelineStage {
    private let operation: @Sendable (Input) async throws -> Output

    public init(
        _ operation: @escaping @Sendable (Input) async throws -> Output
    ) {
        self.operation = operation
    }

    public func execute(_ input: Input) async throws -> Output {
        try await operation(input)
    }
}
