//
//  Created by Aung Ko Min on 9/4/26.
//

struct ExampleSnapshot {
    let isLoading: Bool
    let error: String?
	let items: [String]
}

@MainActor
protocol ExampleRepository {
    func loadInitial() async throws -> ExampleSnapshot
    func refresh() async throws -> ExampleSnapshot
    func submit() async throws -> ExampleSnapshot
    func latestSnapshot() async -> ExampleSnapshot
}
