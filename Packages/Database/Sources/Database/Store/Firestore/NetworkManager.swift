// © 2026 Aung Ko Min

import Core
import Foundation
import Network
import XUI

// MARK: - NetworkActor

@globalActor
public struct NetworkActor {
    public actor NetworkActor {}

    public static let shared: NetworkActor = .init()
}

// MARK: - NetworkManager

@NetworkActor
public final class NetworkManager: NSObject {
    public static let shared: NetworkManager = .init()

    private let monitor: NWPathMonitor = .init()
    private let monitorQueue: DispatchQueue = .init(
        label: AppInformation.appID + ".NetworkMonitor",
    )

    private let session: URLSession
    private var lastPathStatus: NWPath.Status? = nil
    public private(set) var isConnected: Bool = false

    override init() {
        let config: URLSessionConfiguration = {
            $0.waitsForConnectivity = true
            $0.waitsForConnectivity = true
            $0.timeoutIntervalForRequest = 30
            $0.timeoutIntervalForResource = 120
            $0.allowsConstrainedNetworkAccess = true
            $0.allowsExpensiveNetworkAccess = true
            return $0
        }(
            URLSessionConfiguration.default
        )
        session = .init(
            configuration: config,
        )
        super.init()
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @NetworkActor in
                guard let self else {
                    return
                }

                self.isConnected = (path.status == .satisfied)
                if path.status != self.lastPathStatus {
                    if self.lastPathStatus != nil {
                        Task { @MainActor in
                            if path.status == .satisfied {
                                ToastPresenter
                                    .show("connected", allowsBackgroundTap: false)
                            } else {
                                ToastPresenter
                                    .show("no connection", allowsBackgroundTap: false)
                            }
                        }
                    }
                    self.lastPathStatus = path.status
                }
            }
        }
        monitor
            .start(
                queue: monitorQueue,
            )
    }

    public func request(
        _ urlRequest: URLRequest,
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 0.5,
    ) async throws -> (
        Data,
        URLResponse,
    ) {
        try await request(
            makeRequest: {
                urlRequest
            },
            maxRetries: maxRetries,
            baseDelay: baseDelay,
        )
    }

    public func request(
        makeRequest: @escaping () -> URLRequest,
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 0.5,
    ) async throws -> (
        Data,
        URLResponse,
    ) {
        var attempt = 0
        var lastError: Error?

        while attempt <= maxRetries {
            try Task
                .checkCancellation()

            let request = makeRequest()

            do {
                let (
                    data,
                    response,
                ) = try await session.data(
                    for: request,
                )
                if let http = response as? HTTPURLResponse {
                    if isTransient(
                        statusCode: http.statusCode,
                    ), attempt < maxRetries {
                        // Honor Retry-After if provided
                        let delay = retryDelay(
                            from: http,
                            attempt: attempt,
                            base: baseDelay,
                        )
                        try? await Task
                            .sleep(
                                nanoseconds: UInt64(
                                    delay * 1_000_000_000,
                                ),
                            )
                        attempt += 1
                        continue
                    }
                    guard
                        (200 ..< 300).contains(
                            http.statusCode,
                        ) else
                    {
                        // Non-transient HTTP error: surface it
                        throw URLError(
                            .badServerResponse,
                        )
                    }
                }
                return (
                    data,
                    response,
                )
            } catch {
                lastError = error
                if Task.isCancelled {
                    throw CancellationError()
                }

                if shouldRetry(
                    error: error,
                ), attempt < maxRetries {
                    let jitter = Double.random(
                        in: 0 ... (baseDelay / 2),
                    )
                    let delay =
                        pow(
                            2.0,
                            Double(
                                attempt,
                            ),
                        ) * baseDelay + jitter
                    try? await Task
                        .sleep(
                            nanoseconds: UInt64(
                                delay * 1_000_000_000,
                            ),
                        )
                    attempt += 1
                    continue
                } else {
                    throw error
                }
            }
        }
        throw lastError
            ?? URLError(
                .unknown,
            )
    }

    private func shouldRetry(error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cannotConnectToHost, // -1004
                 .cannotFindHost, // -1003
                 .dnsLookupFailed, // -1006
                 .networkConnectionLost, // -1005
                 .notConnectedToInternet, // -1009
                 .timedOut: // -1001
                return true
            case .cancelled:
                return false
            default:
                return false
            }
        }
        return false
    }

    private func isTransient(statusCode: Int) -> Bool {
        // Retry on common transient server/client throttle responses
        switch statusCode {
        case 429,
             500,
             502,
             503,
             504:
            true
        default:
            false
        }
    }

    private func retryDelay(
        from http: HTTPURLResponse,
        attempt: Int,
        base: TimeInterval,
    ) -> TimeInterval {
        if let retryAfter = http.value(
            forHTTPHeaderField: "Retry-After",
        ) {
            if let seconds = TimeInterval(
                retryAfter,
            ) {
                return seconds
            }
            // Retry-After can also be a HTTP-date; you could parse it if needed.
        }
        let jitter = Double.random(
            in: 0 ... (base / 2),
        )
        return pow(
            2.0,
            Double(
                attempt,
            ),
        ) * base + jitter
    }
}

// MARK: URLSessionDelegate, URLSessionTaskDelegate

extension NetworkManager: URLSessionDelegate, URLSessionTaskDelegate {
    public nonisolated func urlSession(
        _: URLSession,
        task _: URLSessionTask,
        didCompleteWithError error: Error?,
    ) {
        if let error = error as? URLError, error.code == .networkConnectionLost {
            // Good place to log diagnostics or enqueue a retry
            // print("Task \(task.taskIdentifier) connection lost")
        }
    }

    public nonisolated func urlSession(
        _: URLSession,
        task _: URLSessionTask,
        didFinishCollecting _: URLSessionTaskMetrics,
    ) {
        // Inspect metrics for connection reuse, protocol (HTTP/2), etc.
        // metrics.transactionMetrics.forEach { print($0.networkProtocolName ?? "unknown") }
    }
}
