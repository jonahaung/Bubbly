import Foundation

struct HTTPRequestExecutor: Sendable {
    enum Body: Sendable {
        case data(Data)
        case file(URL)
    }

    private let configurationProvider: @Sendable () throws -> HTTPClientConfiguration
    private let accessTokenProvider: HTTPAccessTokenProvider
    private let transport: any HTTPTransport

    init(
        configurationProvider: @escaping @Sendable () throws -> HTTPClientConfiguration,
        accessTokenProvider: @escaping HTTPAccessTokenProvider,
        transport: any HTTPTransport
    ) {
        self.configurationProvider = configurationProvider
        self.accessTokenProvider = accessTokenProvider
        self.transport = transport
    }

    func send<R: APIRequest>(_ request: R) async throws -> R.Response {
        let body: Body?
        if let model = request.body {
            let data = try encode(model)
            body = .data(data)
        } else {
            body = nil
        }
        let data = try await requiredResponse(
            method: request.method.rawValue,
            path: request.paths,
            body: body,
            contentType: request.contentType
        )
        return try decode(R.Response.self, from: data)
    }
    func requiredResponse(
        method: String,
        path: [String],
        queryItems: [URLQueryItem] = [],
        body: Body? = nil,
        contentType: String? = nil
    ) async throws -> Data {
        guard
            let data = try await send(
                method: method,
                path: path,
                queryItems: queryItems,
                body: body,
                contentType: contentType
            )
        else {
            throw HTTPError.invalidResponse
        }
        return data
    }

    func send(
        method: String,
        path: [String],
        queryItems: [URLQueryItem] = [],
        body: Body? = nil,
        contentType: String? = nil,
        allowsNotFound: Bool = false
    ) async throws -> Data? {
        let configuration = try configurationProvider()
        var retry = 0
        var forceTokenRefresh = false

        while true {
            try Task.checkCancellation()
            let request = try await makeRequest(
                configuration: configuration,
                method: method,
                path: path,
                queryItems: queryItems,
                body: body,
                contentType: contentType,
                forceTokenRefresh: forceTokenRefresh
            )

            let response: HTTPResponse
            do {
                response = try await perform(request: request, body: body)
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as URLError {
                if error.code == .cancelled || Task.isCancelled {
                    throw CancellationError()
                }
                guard retry < configuration.retryPolicy.maximumRetryCount,
                    Self.isRetryable(error.code)
                else {
                    throw HTTPError.network(error.code)
                }
                try await sleepBeforeRetry(retry, policy: configuration.retryPolicy)
                retry += 1
                continue
            } catch let error as HTTPError {
                throw error
            } catch {
                throw HTTPError.transportFailure
            }

            switch response.statusCode {
            case 200..<300:
                return response.data
            case 401 where !forceTokenRefresh:
                forceTokenRefresh = true
                continue
            case 404 where allowsNotFound:
                return nil
            case let statusCode
            where Self.isRetryable(statusCode)
                && retry < configuration.retryPolicy.maximumRetryCount:
                let retryAfter = Self.retryAfter(from: response.headers)
                try await sleepBeforeRetry(retry, policy: configuration.retryPolicy, retryAfter: retryAfter)
                retry += 1
            default:
                let errorResponse = try? JSONDecoder().decode(BackendErrorResponse.self, from: response.data)
                throw HTTPError.rejected(
                    statusCode: response.statusCode,
                    message: errorResponse?.reason ?? ""
                )
            }
        }
    }

    func encode<T: Encodable>(_ value: T) throws -> Data {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(value)
        } catch {
            throw HTTPError.invalidRequest("The request could not be encoded.")
        }
    }

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        } catch {
            throw HTTPError.invalidResponse
        }
    }

    private func makeRequest(
        configuration: HTTPClientConfiguration,
        method: String,
        path: [String],
        queryItems: [URLQueryItem],
        body: Body?,
        contentType: String?,
        forceTokenRefresh: Bool
    ) async throws -> URLRequest {
        let token = try await accessTokenProvider(forceTokenRefresh)
        guard !token.isEmpty else {
            throw HTTPError.notAuthenticated
        }
        let url = try makeURL(baseURL: configuration.baseURL, path: path, queryItems: queryItems)
        var request = URLRequest(url: url, timeoutInterval: configuration.requestTimeout)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        if let contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        if let body {
            switch body {
            case .data(let data):
                request.httpBody = data
            case .file(let uRL):
                let data = try Data.init(contentsOf: uRL)
                request.httpBody = data
            }
        }
        return request
    }

    private func perform(request: URLRequest, body: Body?) async throws -> HTTPResponse {
        if case let .file(fileURL) = body {
            return try await transport.upload(for: request, fromFile: fileURL)
        }
        return try await transport.data(for: request)
    }

    private func makeURL(baseURL: URL, path: [String], queryItems: [URLQueryItem]) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw HTTPError.invalidConfiguration
        }
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/?#%")
        let encodedPath = try path.map { component in
            guard let encoded = component.addingPercentEncoding(withAllowedCharacters: allowed) else {
                throw HTTPError.invalidRequest("The request path is invalid.")
            }
            return encoded
        }
        let basePath = components.percentEncodedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.percentEncodedPath =
            "/"
            + ([basePath] + encodedPath)
            .filter { !$0.isEmpty }
            .joined(separator: "/")
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else {
            throw HTTPError.invalidRequest("The request URL is invalid.")
        }
        return url
    }

    private func sleepBeforeRetry(
        _ retry: Int,
        policy: HTTPRetryPolicy,
        retryAfter: Duration? = nil
    ) async throws {
        let delay = min(retryAfter ?? policy.delay(forRetry: retry), policy.maximumDelay)
        if delay > .zero {
            try await Task.sleep(for: delay)
        }
    }

    private static func isRetryable(_ code: URLError.Code) -> Bool {
        switch code {
        case .timedOut, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost,
            .dnsLookupFailed, .notConnectedToInternet, .internationalRoamingOff,
            .callIsActive, .dataNotAllowed, .secureConnectionFailed:
            true
        default:
            false
        }
    }

    private static func isRetryable(_ statusCode: Int) -> Bool {
        [408, 429, 500, 502, 503, 504].contains(statusCode)
    }

    private static func retryAfter(from headers: [String: String]) -> Duration? {
        guard let value = headers["retry-after"], let seconds = Int64(value), seconds >= 0 else {
            return nil
        }
        return .seconds(seconds)
    }
}
