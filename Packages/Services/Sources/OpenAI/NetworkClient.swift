//
//  NetworkClient.swift
//  InterviewHacker
//
//  Created by Aung Ko Min on 27/2/25.
//

import Foundation

// MARK: - NetworkClient
public protocol NetworkClient: Sendable {
    func sendRequest<T: Decodable>(to endpoint: URL, with body: Data) async throws -> T
}

public struct URLSessionNetworkClient: NetworkClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func sendRequest<T: Decodable>(to endpoint: URL, with body: Data) async throws -> T {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
}
extension URLSessionNetworkClient: Sendable {}
