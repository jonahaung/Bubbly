public protocol PipelineStage<Input, Output>: Sendable {
    associatedtype Input: Sendable
    associatedtype Output: Sendable

    func execute(_ input: Input) async throws -> Output
}
