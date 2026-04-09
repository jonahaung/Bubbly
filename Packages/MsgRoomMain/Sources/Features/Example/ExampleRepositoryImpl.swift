//
//  Created by Aung Ko Min on 9/4/26.
//

import XUI

@MainActor
struct ExampleRepositoryImpl: ExampleRepository {
    private let manager: ExampleManager

    init(manager: ExampleManager) {
        self.manager = manager
    }

    func loadInitial() async throws -> ExampleSnapshot {
        manager.setLoading(false)
        manager.setError(nil)
        return snapshot()
    }

    func refresh() async throws -> ExampleSnapshot {
        manager.setLoading(false)
        manager.setError(nil)
        return snapshot()
    }

    func submit() async throws -> ExampleSnapshot {
        manager.setLoading(false)
        manager.setError(nil)
        return snapshot()
    }

    func latestSnapshot() async -> ExampleSnapshot {
        snapshot()
    }

    private func snapshot() -> ExampleSnapshot {
		let items: [String] = {
			var items: [String] = []
			for _ in 0..<1000 {
				items.append(Lorem.random())
			}
			return items
		}()
		return .init(
			isLoading: manager.isLoading,
			error: manager.error,
			items: items.uniqued()
		)
    }
}
