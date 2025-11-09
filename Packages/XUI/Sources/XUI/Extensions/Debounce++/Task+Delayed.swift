import Foundation

public extension Task {
    @discardableResult
    static func delayed(
        seconds: TimeInterval,
        operation: @Sendable @escaping () async -> Void
    ) -> Self where Success == Void, Failure == Never {
        Self {
            do {
                try await Task<Never, Never>.sleep(seconds: seconds)
                await operation()
            } catch {
                Log(error)
            }
        }
    }
}
