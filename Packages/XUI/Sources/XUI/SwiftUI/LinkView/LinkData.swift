//
//  LinkData.swift
//  XUI
//
//  Created by Aung Ko Min on 20/9/25.
//


import Foundation
import UniformTypeIdentifiers
import LinkPresentation
import UIKit

public struct LinkData: AsyncFetchingItem {

	public let image: UIImage?
	public let title: String?
	public let subtitle: String?

	public init(image: UIImage?, title: String?, subtitle: String?) {
		self.image = image
		self.title = title
		self.subtitle = subtitle
	}

	public static func performFetch(for fechIdentifier: URL) async throws -> LinkData {
		let provider = LPMetadataProvider()
		let request = URLRequest(url: fechIdentifier, cachePolicy: .reloadIgnoringCacheData)
		let metadata = try await provider.startFetchingMetadata(for: request)
		let title = metadata.title
		let subtitle = metadata.url?.host()
		let image = try await fetchImage(from: metadata.imageProvider)
		return .init(image: image, title: title, subtitle: subtitle)
	}

	private static func fetchImage(from imageProvider: NSItemProvider?) async throws -> UIImage? {
		guard let imageProvider else { return nil }
		let utType = UTType.image.identifier
		let item = try await imageProvider.loadItem(forTypeIdentifier: utType)

		switch item {
		case let uiImage as UIImage:
			return uiImage
		case let url as URL:
			let data = try Data(contentsOf: url)
			return UIImage(data: data)
		case let data as Data:
			return UIImage(data: data)
		default:
			return nil
		}
	}
}
