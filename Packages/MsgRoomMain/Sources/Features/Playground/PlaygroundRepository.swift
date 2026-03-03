//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

struct PlaygroundSnapshot {
    let isLoading: Bool
    let error: String?
}

@MainActor
protocol PlaygroundRepository {
    func loadInitial() async throws -> PlaygroundSnapshot
    func refresh() async throws -> PlaygroundSnapshot
    func submit() async throws -> PlaygroundSnapshot
    func latestSnapshot() async -> PlaygroundSnapshot
}
