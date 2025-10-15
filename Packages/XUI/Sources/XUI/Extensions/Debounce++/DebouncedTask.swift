import SwiftUI

extension View {
    public func task<T>(
        id value: T,
        priority: TaskPriority = .userInitiated,
        debounceTime: Duration,
        _ action: @Sendable @escaping () async -> Void
    ) -> some View where T: Equatable {
        self.task(id: value, priority: priority) {
            do { try await Task.sleep(for: debounceTime) } catch { return }
            await action()
        }
    }
}
