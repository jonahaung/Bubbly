//
//  SwiftLinkPreviewType.swift
//  XUI
//
//  Created by Aung Ko Min on 16/12/25.
//

import Foundation

public protocol SwiftLinkPreviewType {
	func preview(
		_ text: String,
		onSuccess: @escaping (SwiftLinkPreviewResponse) -> Void,
		onError: @escaping (SwiftLinkPreviewError) -> Void
	) -> CancellableType
	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, visionOS 1.0, macCatalyst 13.0, *)
	func preview(_ text: String) async throws -> SwiftLinkPreviewResponse
	func previewLink(
		_ text: String,
		onSuccess: @escaping ([String: Any]) -> Void,
		onError: @escaping (NSError) -> Void
	) -> CancellableType
	func crawlMetaTags(_ htmlCode: String, result: SwiftLinkPreviewResponse) -> SwiftLinkPreviewResponse
	func crawlImages(_ htmlCode: String, result: SwiftLinkPreviewResponse) -> SwiftLinkPreviewResponse
	func extractURL(text: String) -> URL?
	func extractCanonicalURL(_ finalUrl: URL) -> String
	func crawIcon(_ htmlCode: String, result: SwiftLinkPreviewResponse) -> SwiftLinkPreviewResponse
	func crawlCode(_ content: String, minimum: Int) -> String
	func crawlDescription(_ htmlCode: String, result: SwiftLinkPreviewResponse) -> (htmlCode: String, result: SwiftLinkPreviewResponse)
	func crawlTitle(_ htmlCode: String, result: SwiftLinkPreviewResponse) -> (htmlCode: String, result: SwiftLinkPreviewResponse)
	func crawlMetaBase(_ htmlCode: String, result: SwiftLinkPreviewResponse) -> SwiftLinkPreviewResponse
	func formatImageURLs(_ array: [String]?, base: String?) -> [String]?
}
