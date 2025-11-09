//
//  OpenAIClient.swift
//  InterviewHacker
//
//  Created by Aung Ko Min on 27/2/25.
//

import Database
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
public protocol NetworkClient: Sendable {
    func sendRequest<T: Decodable>(
        to endpoint: URL,
        with body: Data
    ) async throws -> T
}

public struct URLSessionNetworkClient: NetworkClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func sendRequest<T: Decodable>(
        to endpoint: URL,
        with body: Data
    ) async throws -> T {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 30

        let (data, response) = try await NetworkManager.shared.request(request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

extension URLSessionNetworkClient: Sendable {}
