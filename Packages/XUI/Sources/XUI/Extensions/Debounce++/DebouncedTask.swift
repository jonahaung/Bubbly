import SwiftUI

public extension View {
	func task(id value: some Equatable,
	          priority: TaskPriority = .userInitiated,
	          debounceTime: Duration,
	          _ action: @Sendable @escaping () async -> Void) -> some View
	{
		task(id: value, priority: priority) {
			do { try await Task.sleep(for: debounceTime) } catch { return }
			await action()
		}
	}
}
