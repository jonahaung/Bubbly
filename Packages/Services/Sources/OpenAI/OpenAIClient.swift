//
//  OpenAIClient.swift
//  InterviewHacker
//
//  Created by Aung Ko Min on 27/2/25.
//

import Foundation

// MARK: - OpenAIClient
public struct OpenAIClient {
    private let networkClient: NetworkClient
    private let endpoint: URL

    public init(
        networkClient: NetworkClient = URLSessionNetworkClient(),
        endpoint: URL = URL(string: "https://icecubesrelay.fly.dev/openai")!
    ) {
        self.networkClient = networkClient
        self.endpoint = endpoint
    }

    public func request(_ prompt: OpenAIPrompt) async throws -> OpenAIResponse {
        let jsonData = try JSONEncoder().encode(prompt.request)
        return try await networkClient.sendRequest(to: endpoint, with: jsonData)
    }
}
extension OpenAIClient: Sendable {}
