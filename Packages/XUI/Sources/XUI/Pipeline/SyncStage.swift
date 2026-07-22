public struct SyncStage<Input: Sendable, Output: Sendable>: PipelineStage {
    private let transform: @Sendable (Input) throws -> Output

    public init(
        _ transform: @escaping @Sendable (Input) throws -> Output
    ) {
        self.transform = transform
    }

    public func execute(_ input: Input) async throws -> Output {
        try transform(input)
    }
}
