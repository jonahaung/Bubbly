//
//  SwiftLinkPreviewResponse.swift
//  XUI
//
//  Created by Aung Ko Min on 16/12/25.
//

import Foundation

public struct SwiftLinkPreviewResponse: Sendable, Hashable {

    public internal(set) var url: URL
    public internal(set) var finalUrl: URL
    public internal(set) var canonicalUrl: String
	public internal(set) var baseURL: String

    public internal(set) var title: String?
    public internal(set) var description: String?
    public internal(set) var images: [String]?
    public internal(set) var image: String?
    public internal(set) var icon: String?
    public internal(set) var video: String?
    public internal(set) var price: String?

	public init(_ url: URL, finalUrl: URL, canonicalUrl: String, baseURL: String) {
		self.url = url
		self.finalUrl = finalUrl
		self.canonicalUrl = canonicalUrl
		self.baseURL = baseURL
	}

	public var imageURL: URL? {
		guard let urlString = image ?? icon else {
			return nil
		}
		return .init(string: urlString)
	}
}
