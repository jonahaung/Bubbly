import Foundation

protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> HTTPResponse
    func upload(for request: URLRequest, fromFile fileURL: URL) async throws -> HTTPResponse
}

struct URLSessionBackendHTTPTransport: HTTPTransport {
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> HTTPResponse {
        let (data, response) = try await session.data(for: request)
        return try makeResponse(data: data, response: response)
    }

    func upload(for request: URLRequest, fromFile fileURL: URL) async throws -> HTTPResponse {
        let (data, response) = try await session.upload(for: request, fromFile: fileURL)
        return try makeResponse(data: data, response: response)
    }

    private func makeResponse(data: Data, response: URLResponse) throws -> HTTPResponse {
        guard let response = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }
        let headers = response.allHeaderFields.reduce(into: [String: String]()) { result, element in
            guard let key = element.key as? String, let value = element.value as? String else {
                return
            }
            result[key.lowercased()] = value
        }
        return HTTPResponse(statusCode: response.statusCode, headers: headers, data: data)
    }
}
