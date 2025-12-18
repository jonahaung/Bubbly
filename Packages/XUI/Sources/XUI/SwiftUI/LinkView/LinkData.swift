//
//  LinkData.swift
//  XUI
//
//  Created by Aung Ko Min on 20/9/25.
//

import Foundation
@preconcurrency import LinkPresentation
import UIKit
import UniformTypeIdentifiers

public struct LinkData: AsyncFetchingItem {
    public let image: UIImage?
    public let title: String?
    public let subtitle: String?

    public init(image: UIImage?, title: String?, subtitle: String?) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
    }

    // LinkData stores UIImage (non-Sendable), but AsyncFetchingItem requires Sendable.
    // We guarantee safe use by not sharing mutable state and treating instances as immutable value containers.
    // Therefore, we mark it @unchecked Sendable.
}

extension LinkData: @unchecked Sendable {}

public extension LinkData {
    // MARK: - Public API

    static func performFetch(for fetchIdentifier: URL) async throws -> LinkData {
        // 1) Resolve redirects to get a stable final URL
        let finalURL = await resolveFinalURL(for: fetchIdentifier) ?? fetchIdentifier

        // 2) Try LinkPresentation first with timeout & retry
        if let lp = try? await fetchLPMetadata(for: finalURL, retries: 2, timeout: 8) {
            let title = lp.title
            let subtitle = lp.url?.host()
            let image = try? await fetchImage(from: lp.imageProvider)
            return .init(image: image, title: title, subtitle: subtitle)
        }

        // 3) Fallback to simple Open Graph parsing
        if let og = try? await fetchOpenGraph(from: finalURL) {
            var image: UIImage?
            if let imageURL = og.imageURL {
                image = await downloadImage(from: imageURL)
            } else if let host = finalURL.host, let scheme = finalURL.scheme {
                // 4) As a last resort, try favicon
                let faviconURL = URL(string: "\(scheme)://\(host)/favicon.ico")
                if let faviconURL {
                    image = await downloadImage(from: faviconURL)
                }
            }
            return .init(image: image, title: og.title ?? og.pageTitle, subtitle: finalURL.host())
        }

        // 4) Final fallback: try favicon only
        var fallbackImage: UIImage?
        if let host = finalURL.host, let scheme = finalURL.scheme {
            let faviconURL = URL(string: "\(scheme)://\(host)/favicon.ico")
            if let faviconURL {
                fallbackImage = await downloadImage(from: faviconURL)
            }
        }
        return .init(image: fallbackImage, title: nil, subtitle: finalURL.host())
    }

    // MARK: - LPMetadataProvider path

    private static func fetchLPMetadata(for url: URL, retries: Int, timeout: TimeInterval) async throws -> LPLinkMetadata {
        var lastError: Error?
        for attempt in 0...retries {
            if Task.isCancelled { throw CancellationError() }
            do {
                let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)

                // Create provider locally and keep it confined to the task that uses it.
                let provider = LPMetadataProvider()

                // Race the metadata fetch against a timeout without sharing mutable state across tasks.
                let result: LPLinkMetadata = try await withThrowingTaskGroup(of: LPLinkMetadata.self) { group in
                    // Fetch task
                    group.addTask {
                        // Use the provider only inside this task
                        let md = try await provider.startFetchingMetadata(for: request)
                        return md
                    }
                    // Timeout task
                    group.addTask {
                        let ns = UInt64(max(0, timeout) * 1_000_000_000)
                        try await Task.sleep(nanoseconds: ns)
                        // If we get here first, cancel the provider and throw timeout
                        provider.cancel()
                        throw URLError(.timedOut)
                    }

                    // Return the first child task that completes successfully; if one throws, propagate if it's the only remaining.
                    defer { group.cancelAll() }

                    // Wait for first finished child
                    do {
                        let value = try await group.next()!
                        return value
                    } catch {
                        // If the first finished threw, consume the second to see if it succeeds before we propagate.
                        // If the second succeeds, prefer it; otherwise throw the original error.
                        if let second = try? await group.next() {
                            return second
                        }
                        throw error
                    }
                }

                return result
            } catch {
                lastError = error
                if shouldRetry(error: error), attempt < retries {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                    continue
                } else {
                    throw error
                }
            }
        }
        throw lastError ?? URLError(.unknown)
    }

    private static func shouldRetry(error: Error) -> Bool {
        let nsError = error as NSError
        // LPErrorDomain (2) or WebKit 102 or timeout
        if nsError.domain == "LPErrorDomain" { return true }
        if nsError.domain == "WebKitErrorDomain", nsError.code == 102 { return true }
        if (error as? URLError)?.code == .timedOut { return true }
        return false
    }

    // MARK: - NSItemProvider image extraction

    private static func fetchImage(from imageProvider: NSItemProvider?) async throws -> UIImage? {
        guard let imageProvider else { return nil }
        let utType = UTType.image.identifier

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UIImage?, Error>) in
            imageProvider.loadItem(forTypeIdentifier: utType) { (item, error) in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let item else {
                    continuation.resume(returning: nil)
                    return
                }
                if let uiImage = item as? UIImage {
                    continuation.resume(returning: uiImage)
                } else if let url = item as? URL {
                    do {
                        let data = try Data(contentsOf: url)
                        continuation.resume(returning: UIImage(data: data))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                } else if let data = item as? Data {
                    continuation.resume(returning: UIImage(data: data))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // MARK: - Redirect resolution

    private static func resolveFinalURL(for url: URL) async -> URL? {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 8)
        request.httpMethod = "GET"
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, let final = http.url {
                return final
            }
        } catch {
            // Ignore resolution failures; just use the original URL
        }
        return nil
    }

    // MARK: - Open Graph fallback

    private struct OGResult {
        let title: String?
        let description: String?
        let imageURL: URL?
        let pageTitle: String?
    }

    private static func fetchOpenGraph(from url: URL) async throws -> OGResult {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 8)
        request.httpMethod = "GET"
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...399).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw URLError(.cannotDecodeContentData)
        }
        let pageTitle = firstMatch(in: html, pattern: "<title[^>]*>(.*?)</title>")
        let ogTitle = firstMetaProperty(in: html, property: "og:title") ?? firstMetaName(in: html, name: "twitter:title")
        let ogDescription = firstMetaProperty(in: html, property: "og:description") ?? firstMetaName(in: html, name: "description") ?? firstMetaName(in: html, name: "twitter:description")
        let ogImageString = firstMetaProperty(in: html, property: "og:image") ?? firstMetaName(in: html, name: "twitter:image")
        let imageURL: URL?
        if let ogImageString, let absolute = URL(string: ogImageString, relativeTo: response.url ?? url) {
            imageURL = absolute
        } else {
            imageURL = nil
        }
        return OGResult(title: ogTitle, description: ogDescription, imageURL: imageURL, pageTitle: pageTitle)
    }

    private static func firstMetaProperty(in html: String, property: String) -> String? {
        // Searches: <meta property="og:title" content="...">
        let pattern = "<meta[^>]*property=[\"']\(NSRegularExpression.escapedPattern(for: property))[\"'][^>]*content=[\"'](.*?)[\"'][^>]*>"
        return firstMatch(in: html, pattern: pattern)
    }

    private static func firstMetaName(in html: String, name: String) -> String? {
        // Searches: <meta name="description" content="...">
        let pattern = "<meta[^>]*name=[\"']\(NSRegularExpression.escapedPattern(for: name))[\"'][^>]*content=[\"'](.*?)[\"'][^>]*>"
        return firstMatch(in: html, pattern: pattern)
    }

    private static func firstMatch(in html: String, pattern: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            if let match = regex.firstMatch(in: html, options: [], range: range), match.numberOfRanges > 1,
               let r = Range(match.range(at: 1), in: html) {
                let value = String(html[r]).trimmingCharacters(in: .whitespacesAndNewlines)
                return value.isEmpty ? nil : value
            }
        } catch {
            // Ignore regex errors
        }
        return nil
    }

    // MARK: - Image download

    private static func downloadImage(from url: URL) async -> UIImage? {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 8)
        request.httpMethod = "GET"
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            return UIImage(data: data)
        } catch {
            return nil
        }
    }

    // MARK: - Description

    var description: String {
        var string = ""
        if let subtitle {
            string.append(subtitle)
        }
        return string
    }
}
