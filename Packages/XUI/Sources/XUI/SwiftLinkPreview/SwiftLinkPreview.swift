//
//  SwiftLinkPreview.swift
//  XUI
//
//  Created by Aung Ko Min on 16/12/25.
//

import Foundation

public final class SwiftLinkPreview: NSObject, @unchecked Sendable {
	// MARK: - Constants

	static let titleMinimumRelevant: Int = 15
	static let decriptionMinimumRelevant: Int = 100

	public let cache: SwiftLinkPreviewCache
	public let userAgent: String

	public static let defaultUserAgent =
	"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36"
	public static let googleBotUserAgent = "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"

	// We keep a session with a delegate to force GET on redirects.
	public private(set) var session: URLSession

	// MARK: - Init

	public init(
		session: URLSession? = nil,
		cache: SwiftLinkPreviewCache = LinkPreviewInMemoryCache.init(),
		userAgent: String = SwiftLinkPreview.defaultUserAgent
	) {
		self.cache = cache
		self.userAgent = userAgent

		if let session {
			self.session = session
		} else {
			// Build a session with delegate to force GET on redirects.
			let config = URLSessionConfiguration.default
			let queue = OperationQueue()
			queue.maxConcurrentOperationCount = 1
			let delegate = RedirectForcingDelegate()
			self.session = URLSession(configuration: config, delegate: delegate, delegateQueue: queue)
		}
		super.init()
	}

	deinit {
		// Break retain cycle between URLSession, its delegate and queue
		session.finishTasksAndInvalidate()
	}

	/// Explicitly close the underlying session if you want to release resources early.
	public func close() {
		session.invalidateAndCancel()
	}

	public func preview(_ text: String) async throws -> SwiftLinkPreviewResponse {
		try Task.checkCancellation()

		guard let url = extractURL(text: text) else {
			throw SwiftLinkPreviewError.noURLHasBeenFound(text)
		}

		// Cache check for original URL
		if let cached = cache.slp_getCachedResponse(url: url.absoluteString) {
			return cached
		}

		// Follow redirects / unshorten
		let unshortened = try await unshortenURL(url)

		// Cache check for final URL
		if let cached = cache.slp_getCachedResponse(url: unshortened.absoluteString) {
			return cached
		}

		let finalUrl = extractInURLRedirectionIfNeeded(unshortened)
		let canonicalUrl = extractCanonicalURL(unshortened)
		let baseUL = (
			canonicalUrl.starts(with: "http") == false
			? "https://\(canonicalUrl)"
			: canonicalUrl
		)

		var result = SwiftLinkPreviewResponse(
			url,
			finalUrl: finalUrl,
			canonicalUrl: canonicalUrl,
			baseURL: baseUL
		)

		// Extract info (network + parse)
		result = try await extractInfo(response: result)

		// Normalize URLs for media fields based on baseURL
		result.image = formatImageURL(result.image, base: result.baseURL)
		result.images = formatImageURLs(result.images, base: result.baseURL)
		result.icon = formatImageURL(result.icon, base: result.baseURL)
		result.video = formatImageURL(result.video, base: result.baseURL)

		// Cache both original and final
		cache.slp_setCachedResponse(url: unshortened.absoluteString, response: result)
		cache.slp_setCachedResponse(url: url.absoluteString, response: result)

		return result
	}

	// MARK: - URL Extraction

	public func extractURL(text: String) -> URL? {
		do {
			let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
			let range = NSRange(location: 0, length: text.utf16.count)
			let matches = detector.matches(in: text, options: [], range: range)
			return matches.compactMap { $0.url }.first
		} catch {
			return nil
		}
	}

	private func unshortenURL(_ url: URL) async throws -> URL {
		try Task.checkCancellation()

		// First try HEAD to follow server redirects
		var headRequest = URLRequest(url: url)
		headRequest.httpMethod = "HEAD"
		headRequest.addValue(userAgent, forHTTPHeaderField: "User-Agent")

		do {
			let (_, headResponse) = try await session.data(for: headRequest)
			if let final = (headResponse as? HTTPURLResponse)?.url {
				// Redirect occurred
				if final.absoluteString != url.absoluteString {
					return try await unshortenURL(final)
				}
				// No redirect. If it's HTML, inspect for meta refresh
				if let mime = (headResponse as? HTTPURLResponse)?.mimeType, mime.contains("/html") {
					// Fetch HTML to check for meta refresh
					var getRequest = URLRequest(url: url)
					getRequest.addValue("text/html,application/xhtml+xml,application/xml", forHTTPHeaderField: "Accept")
					getRequest.addValue(userAgent, forHTTPHeaderField: "User-Agent")
					let (data, response) = try await session.data(for: getRequest)

					let encoding = (response as? HTTPURLResponse)?.textEncodingName.flatMap {
						String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(
							CFStringConvertIANACharSetNameToEncoding($0 as CFString)
						))
					} ?? .utf8

					if let html = String(data: data, encoding: encoding) {
						for meta in Regex.pregMatchAll(html, regex: Regex.metaTagPattern, index: 1) {
							if meta.contains("http-equiv=\"refresh\"") || meta.contains("http-equiv='refresh'"),
							   let value = Regex.pregMatchFirst(meta, regex: Regex.metaTagContentPattern, index: 2)?
								.decoded.extendedTrim,
							   let redirectString = value.split(separator: ";")
								.first(where: { $0.lowercased().starts(with: "url=") })?
								.split(separator: "=", maxSplits: 1).last {
								let redirectTarget = String(redirectString)
								if let redirectURL = URL(string: addImagePrefixIfNeeded(redirectTarget, url: url)) {
									return try await unshortenURL(redirectURL)
								}
							}
						}
					}
				}
				return url
			} else {
				// No URL in response, keep the original
				return url
			}
		} catch {
			// On HEAD error, just return original URL (like legacy behavior would eventually fall back)
			return url
		}
	}

	// Extract HTML code and the information contained on it
	private func extractInfo(response: SwiftLinkPreviewResponse) async throws -> SwiftLinkPreviewResponse {
		try Task.checkCancellation()
		let url = response.finalUrl

		if url.absoluteString.isImage() {
			var result = response
			result.title = ""
			result.description = ""
			result.images = [url.absoluteString]
			result.image = url.absoluteString
			return result
		} else {
			guard let sourceUrl = url.scheme == "http" || url.scheme == "https" ? url : URL(string: "http://\(url)")
			else {
				throw SwiftLinkPreviewError.invalidURL(url.absoluteString)
			}

			var request = URLRequest(url: sourceUrl)
			request.addValue("text/html,application/xhtml+xml,application/xml", forHTTPHeaderField: "Accept")
			request.addValue(userAgent, forHTTPHeaderField: "User-Agent")

			do {
				let (data, urlResponse) = try await session.data(for: request)

				let encoding = (urlResponse as? HTTPURLResponse)?.textEncodingName.flatMap {
					String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(
						CFStringConvertIANACharSetNameToEncoding($0 as CFString)
					))
				}

				// Autorelease pool to promptly reclaim UIKit/CoreGraphics temporaries
				return try autoreleasepool(invoking: { () throws -> SwiftLinkPreviewResponse in
					if let encoding, let source = String(data: data, encoding: encoding) {
						return parseHtmlString(source, response: response)
					} else if let source = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) {
						return parseHtmlString(source, response: response)
					} else {
						// As a last resort (rare), try Data -> NSString auto-detection path
						var ns: NSString?
						NSString.stringEncoding(
							for: data,
							encodingOptions: nil,
							convertedString: &ns,
							usedLossyConversion: nil
						)
						if let ns {
							return parseHtmlString(ns as String, response: response)
						} else {
							throw SwiftLinkPreviewError.cannotBeOpened(sourceUrl.absoluteString)
						}
					}
				})
			} catch {
				// Network or decoding error
				throw SwiftLinkPreviewError.cannotBeOpened("\(sourceUrl.absoluteString): \(error.localizedDescription)")
			}
		}
	}

	private func parseHtmlString(_ htmlString: String, response: SwiftLinkPreviewResponse) -> SwiftLinkPreviewResponse {
		// Keep parsing/crawling in its own autorelease pool to flush intermediates quickly
		return autoreleasepool(invoking: {
			performPageCrawling(cleanSource(htmlString), response: response)
		})
	}

	// Removing unnecessary data from the source
	private func cleanSource(_ source: String) -> String {
		var source = source
		source = source.deleteTagByPattern(Regex.inlineStylePattern)
		source = source.deleteTagByPattern(Regex.inlineScriptPattern)
		source = source.deleteTagByPattern(Regex.scriptPattern)
		source = source.deleteTagByPattern(Regex.commentPattern)
		return source
	}

	// Perform the page crawling
	private func performPageCrawling(
		_ htmlCode: String,
		response: SwiftLinkPreviewResponse
	) -> SwiftLinkPreviewResponse {
		var result = crawIcon(htmlCode, result: response)
		let sanitizedHtmlCode = htmlCode.deleteTagByPattern(Regex.linkPattern).extendedTrim

		result = crawlMetaTags(sanitizedHtmlCode, result: result)
		result = crawlMetaBase(sanitizedHtmlCode, result: result)

		var otherResponse = crawlTitle(sanitizedHtmlCode, result: result)
		otherResponse = crawlDescription(otherResponse.htmlCode, result: otherResponse.result)
		otherResponse = crawlPrice(otherResponse.htmlCode, result: otherResponse.result)

		return crawlImages(otherResponse.htmlCode, result: otherResponse.result)
	}

	// Extract url redirection inside the GET query.
	private func extractInURLRedirectionIfNeeded(_ url: URL) -> URL {
		var url = url
		var absoluteString = url.absoluteString + "&id=12"

		if let range = absoluteString.range(of: "url="),
		   let lastChar = absoluteString.last,
		   let lastCharIndex = absoluteString
			.range(of: String(lastChar), options: .backwards, range: nil, locale: nil) {
			absoluteString = String(absoluteString[range.upperBound ..< lastCharIndex.upperBound])

			if let range = absoluteString.range(of: "&"),
			   let firstChar = absoluteString.first,
			   let firstCharIndex = absoluteString.firstIndex(of: firstChar) {
				absoluteString = String(absoluteString[firstCharIndex ..< absoluteString.index(before: range.upperBound)])

				if let decoded = absoluteString.removingPercentEncoding, let newURL = URL(string: decoded) {
					url = newURL
				}
			}
		}
		return url
	}

	// MARK: - Formatting

	private func formatImageURL(_ url: String?, base: String?) -> String? {
		guard var url else { return nil }
		if !url.starts(with: "http"), let base = base {
			url = "\(base)\(url)"
		}
		return url
	}

	public func formatImageURLs(_ array: [String]?, base: String?) -> [String]? {
		guard var array else { return nil }
		for i in 0 ..< array.count {
			if let formatted = formatImageURL(array[i], base: base) {
				array[i] = formatted
			}
		}
		return Array(Set(array))
	}

	// MARK: - Canonical URL

	public func extractCanonicalURL(_ finalUrl: URL) -> String {
		let preUrl: String = finalUrl.absoluteString
		let url = preUrl
			.replace("http://", with: "")
			.replace("https://", with: "")
			.replace("file://", with: "")
			.replace("ftp://", with: "")

		if preUrl != url {
			if let canonicalUrl = Regex.pregMatchFirst(url, regex: Regex.cannonicalUrlPattern, index: 1) {
				if !canonicalUrl.isEmpty {
					return extractBaseUrl(canonicalUrl)
				} else {
					return extractBaseUrl(url)
				}
			} else {
				return extractBaseUrl(url)
			}
		} else {
			return extractBaseUrl(preUrl)
		}
	}

	fileprivate func extractBaseUrl(_ url: String) -> String {
		return String(url.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: true)[0])
	}
}

// MARK: - Tag functions

public extension SwiftLinkPreview {
	// search for favicon
	func crawIcon(_ htmlCode: String, result: SwiftLinkPreviewResponse) -> SwiftLinkPreviewResponse {
		var result = result
		let metatags = Regex.pregMatchAll(htmlCode, regex: Regex.linkPattern, index: 1)

		let filters = [
			{ (link: String) -> Bool in link.range(of: "apple-touch") != nil },
			{ (link: String) -> Bool in link.range(of: "shortcut") != nil },
			{ (link: String) -> Bool in link.range(of: "icon") != nil }
		]

		for filter in filters {
			if let first = metatags.filter(filter).first {
				let matches = Regex.pregMatchAll(first, regex: Regex.hrefPattern, index: 1)
				if let val = matches.first {
					result.icon = addImagePrefixIfNeeded(val.replace("\"", with: ""), result: result)
					return result
				}
			}
		}
		return result
	}

	// Search for meta tags
	func crawlMetaTags(_ htmlCode: String, result: SwiftLinkPreviewResponse) -> SwiftLinkPreviewResponse {
		var result = result

		let possibleTags: [String] = [
			SwiftLinkPreviewResponse.Key.title.rawValue,
			SwiftLinkPreviewResponse.Key.description.rawValue,
			SwiftLinkPreviewResponse.Key.image.rawValue,
			SwiftLinkPreviewResponse.Key.video.rawValue
		]

		let metatags = Regex.pregMatchAll(htmlCode, regex: Regex.metaTagPattern, index: 1)

		for metatag in metatags {
			for tag in possibleTags {
				if metatag.range(of: "property=\"og:\(tag)") != nil ||
					metatag.range(of: "property='og:\(tag)") != nil ||
					metatag.range(of: "name=\"twitter:\(tag)") != nil ||
					metatag.range(of: "name='twitter:\(tag)") != nil ||
					metatag.range(of: "name=\"\(tag)") != nil ||
					metatag.range(of: "name='\(tag)") != nil ||
					metatag.range(of: "itemprop=\"\(tag)") != nil ||
					metatag.range(of: "itemprop='\(tag)") != nil {
					if let key = SwiftLinkPreviewResponse.Key(rawValue: tag), result.value(for: key) == nil {
						if let value = Regex.pregMatchFirst(metatag, regex: Regex.metaTagContentPattern, index: 2) {
							let value = value.decoded.extendedTrim
							if tag == "image" {
								let value = addImagePrefixIfNeeded(value, result: result)
								if value.isOpenGraphImage() { result.set(value, for: key) }
							} else if tag == "video" {
								let value = addImagePrefixIfNeeded(value, result: result)
								if value.isVideo() { result.set(value, for: key) }
							} else {
								result.set(value, for: key)
							}
						}
					}
				}
			}
		}
		return result
	}

	func crawlMetaBase(_ htmlCode: String, result: SwiftLinkPreviewResponse) -> SwiftLinkPreviewResponse {
		var result = result
		if let base = Regex.pregMatchAll(htmlCode, regex: Regex.baseTagPattern, index: 2).first {
			result.set(base, for: .baseURL)
		}
		return result
	}

	func crawlTitle(_ htmlCode: String, result: SwiftLinkPreviewResponse) -> (htmlCode: String, result: SwiftLinkPreviewResponse) {
		var result = result
		let title = result.title

		if title == nil || title?.isEmpty ?? true {
			if let value = Regex.pregMatchFirst(htmlCode, regex: Regex.titlePattern, index: 2) {
				if value.isEmpty {
					let fromBody: String = crawlCode(htmlCode, minimum: SwiftLinkPreview.titleMinimumRelevant)
					if !fromBody.isEmpty {
						// Keep final decode in an autorelease pool
						autoreleasepool {
							result.title = fromBody.decoded.extendedTrim
						}
						return (htmlCode.replace(fromBody, with: ""), result)
					}
				} else {
					autoreleasepool {
						result.title = value.decoded.extendedTrim
					}
				}
			}
		}
		return (htmlCode, result)
	}

	func crawlDescription(_ htmlCode: String, result: SwiftLinkPreviewResponse) -> (htmlCode: String, result: SwiftLinkPreviewResponse) {
		var result = result
		let description = result.description

		if description == nil || description?.isEmpty ?? true {
			let value: String = crawlCode(htmlCode, minimum: SwiftLinkPreview.decriptionMinimumRelevant)
			if !value.isEmpty {
				autoreleasepool {
					result.description = value.decoded.extendedTrim
				}
			}
		}
		return (htmlCode, result)
	}

	func crawlImages(_ htmlCode: String, result: SwiftLinkPreviewResponse) -> SwiftLinkPreviewResponse {
		var result = result

		let mainImage = result.image

		if mainImage == nil || mainImage?.isEmpty == true {
			let images = result.images

			if images == nil || images?.isEmpty ?? true {
				// Prefer OpenGraph images first
				let values = Regex.pregMatchAll(htmlCode, regex: Regex.secondaryImageTagPattern, index: 2)
				if !values.isEmpty {
					result.images = values
					result.image = values.first
				} else {
					// Fall back to <img> tags
					let values = Regex.pregMatchAll(htmlCode, regex: Regex.imageTagPattern, index: 2)
					if !values.isEmpty {
						let imgs = values.map { self.addImagePrefixIfNeeded($0, result: result) }
						result.images = imgs
						result.image = imgs.first
					}
				}
			}
		} else {
			let values = Regex.pregMatchAll(htmlCode, regex: Regex.secondaryImageTagPattern, index: 2)
			if !values.isEmpty {
				result.images = values
				result.image = values.first
			} else {
				result.images = [addImagePrefixIfNeeded(mainImage ?? String(), result: result)]
			}
		}
		return result
	}

	private func crawlPrice(_ htmlCode: String, result: SwiftLinkPreviewResponse) -> (htmlCode: String, result: SwiftLinkPreviewResponse) {
		var result = result

		let mainPrice = result.price

		if mainPrice == nil || mainPrice?.isEmpty ?? true {
			let values = Regex.pregMatchAll(htmlCode, regex: Regex.pricePattern, index: 1)
			if !values.isEmpty {
				result.price = values.first
			}
		}
		return (htmlCode, result)
	}

	// Add prefix image if needed
	private func addImagePrefixIfNeeded(_ image: String, url: URL) -> String {
		addImagePrefixIfNeeded(
			image,
			canonicalUrl: extractCanonicalURL(url),
			finalUrl: extractInURLRedirectionIfNeeded(url).absoluteString
		)
	}

	private func addImagePrefixIfNeeded(_ image: String, result: SwiftLinkPreviewResponse) -> String {
		addImagePrefixIfNeeded(image, canonicalUrl: result.canonicalUrl, finalUrl: result.finalUrl.absoluteString)
	}

	private func addImagePrefixIfNeeded(_ image: String, canonicalUrl: String, finalUrl: String) -> String {
		var image = image

		if let proto = finalUrl.split(separator: ":").first {
			if image.hasPrefix("/") {
				if image.hasPrefix("//") {
					// image url is //domain/path
					image = proto + ":" + image
				} else {
					// image url is /path relative to base url
					image = proto + "://" + canonicalUrl + image
				}
			} else if !image.contains("://") {
				// image is relative to request url
				let requestUrl = removeSuffixIfNeeded(finalUrl)
				if requestUrl.hasSuffix("/") {
					image = requestUrl + image
				} else {
					image = (requestUrl as NSString).deletingLastPathComponent + "/" + image
				}
			}
		}
		return image
	}

	private func removeSuffixIfNeeded(_ image: String) -> String {
		var image = image
		if let index = image.firstIndex(of: "?") { image = String(image[..<index]) }
		return image
	}

	// Crawl the entire code
	func crawlCode(_ content: String, minimum: Int) -> String {
		let resultFirstSearch = getTagContent("p", content: content, minimum: minimum)
		if !resultFirstSearch.isEmpty {
			return resultFirstSearch
		} else {
			let resultSecondSearch = getTagContent("div", content: content, minimum: minimum)
			if !resultSecondSearch.isEmpty {
				return resultSecondSearch
			} else {
				let resultThirdSearch = getTagContent("span", content: content, minimum: minimum)
				if !resultThirdSearch.isEmpty {
					return resultThirdSearch
				} else {
					if resultThirdSearch.count >= resultFirstSearch.count {
						if resultThirdSearch.count >= resultThirdSearch.count {
							return resultThirdSearch
						} else {
							return resultThirdSearch
						}
					} else {
						return resultFirstSearch
					}
				}
			}
		}
	}

	// Get tag content
	private func getTagContent(_ tag: String, content: String, minimum: Int) -> String {
		let pattern = Regex.tagPattern(tag)
		let index = 2
		let rawMatches = Regex.pregMatchAll(content, regex: pattern, index: index)
		let matches = rawMatches.filter { $0.extendedTrim.tagsStripped.count >= minimum }
		var result = !matches.isEmpty ? matches[0] : ""
		if result.isEmpty {
			if let match = Regex.pregMatchFirst(content, regex: pattern, index: 2) {
				result = match.extendedTrim.tagsStripped
			}
		}
		return result
	}
}

// MARK: - RedirectForcingDelegate

private final class RedirectForcingDelegate: NSObject, URLSessionDataDelegate {
	func urlSession(
		_ session: URLSession,
		task: URLSessionTask,
		willPerformHTTPRedirection response: HTTPURLResponse,
		newRequest request: URLRequest,
		completionHandler: @escaping (URLRequest?) -> Void
	) {
		var request = request
		request.httpMethod = "GET"
		completionHandler(request)
	}
}
