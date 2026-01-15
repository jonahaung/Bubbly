//
//  SwiftLinkPreviewCache.swift
//  XUI
//
//  Created by Aung Ko Min on 16/12/25.
//

import Foundation

public protocol SwiftLinkPreviewCache {
    func slp_getCachedResponse(url: String) -> SwiftLinkPreviewResponse?
    func slp_setCachedResponse(url: String, response: SwiftLinkPreviewResponse?)
}

public final class DisabledCache: SwiftLinkPreviewCache {

	nonisolated(unsafe) public static let instance = DisabledCache()

    public func slp_getCachedResponse(url: String) -> SwiftLinkPreviewResponse? { nil }

    public func slp_setCachedResponse(url: String, response: SwiftLinkPreviewResponse?) { }
}

public final class LinkPreviewInMemoryCache: SwiftLinkPreviewCache {
    private var cache = [String: (response: SwiftLinkPreviewResponse, date: Date)]()
    private let invalidationTimeout: TimeInterval
    private let cleanupTimer: DispatchSource?

    // High priority queue for quick responses
    private static let cacheQueue = DispatchQueue(
        label: "SwiftLinkPreviewInMemoryCacheQueue",
        qos: .userInitiated,
        target: DispatchQueue.global(qos: .userInitiated)
    )

    public init(invalidationTimeout: TimeInterval = 300.0, cleanupInterval: TimeInterval = 10.0) {
        self.invalidationTimeout = invalidationTimeout

        self.cleanupTimer = DispatchSource.makeTimerSource(queue: Self.cacheQueue) as? DispatchSource
        cleanupTimer?.schedule(deadline: .now() + cleanupInterval, repeating: cleanupInterval)

        cleanupTimer?.setEventHandler { [weak self] in
            guard let self else { return }
            self.cleanup()
        }

        cleanupTimer?.resume()
    }

	public func cleanup() {
        // Capture an unsafe, nonisolated reference to avoid capturing a non-Sendable class in a @Sendable closure.
        nonisolated(unsafe) let unsafeSelf = self
        Self.cacheQueue.async {
            for (url, data) in unsafeSelf.cache {
                if data.date.timeIntervalSinceNow >= unsafeSelf.invalidationTimeout {
                    unsafeSelf.cache[url] = nil
                }
            }
        }
    }

	public func slp_getCachedResponse(url: String) -> SwiftLinkPreviewResponse? {
        return Self.cacheQueue.sync { [weak self] in
            guard let self, let response = cache[url] else { return nil }

            if response.date.timeIntervalSinceNow >= invalidationTimeout {
                slp_setCachedResponse(url: url, response: nil)
                return nil
            }
            return response.response
        }
    }

	public func slp_setCachedResponse(url: String, response: SwiftLinkPreviewResponse?) {
        Self.cacheQueue.sync { [weak self] in
            guard let self else { return }
            if let response = response {
                cache[url] = (response, Date())
            } else {
                cache[url] = nil
            }
        }
    }

    deinit {
        self.cleanupTimer?.cancel()
    }
}
