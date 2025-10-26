//
//  ImageUploadingService.swift
//  Bubbly
//
//  Created by Aung Ko Min on 23/8/25.
//

import UIKit
import FirebaseStorage
import SwiftUI

public struct ImageUploadingService {

	public enum Path {
		case user(uid: String)
		case group(groupID: String)
		case conversation(conID: String, msgID: String)

		var path: String {
			switch self {
			case .user:
				return "users"
			case .group:
				return "groups"
			case .conversation:
				return "conversations"
			}
		}

		var childPath: String {
			switch self {
			case .user(let uid):
				return uid
			case .group(let groupID):
				return groupID
			case .conversation(let conID, let msgID):
				return conID + "/" + msgID
			}
		}
	}

	public enum Error: Swift.Error {
		case resizingFailed
		case dataCreationFailed
	}

	public init() {}

	public func uploadImage(_ image: UIImage, size: CGSize?, to path: Path, onProgress: (@Sendable (Progress?) -> Void)? = nil) async throws -> String {
		let mediaManager = MediaManager.shared

		let uploadingImage: UIImage
		if let size, let resizedImage = image.resizedToFill(size) {
			uploadingImage = resizedImage
		} else {
			uploadingImage = image
		}
		let data = try mediaManager.createData(from: uploadingImage)

		let reference = Storage.storage()
			.reference(withPath: path.path)
			.child(path.childPath)

		let metadata = StorageMetadata()
		metadata.contentType = "image/jpeg"

		_ = try await reference.putDataAsync(
			data,
			metadata: metadata, onProgress: onProgress)
		let url = try await reference.downloadURL()
		return await shortenURL(url.absoluteString)
	}

	func shortenURL(_ longURL: String) async -> String {
		guard let escaped = longURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
			return longURL
		}
		guard let endpoint = URL(string: "https://is.gd/create.php?format=simple&url=\(escaped)") else {
			return longURL
		}
		guard let response = try? await URLSession.shared.data(from: endpoint) else {
			return longURL
		}
		let data = response.0
		return String(decoding: data, as: UTF8.self)
	}
}

extension UIImage {

	public func resizedToFit(in targetSize: CGSize) -> UIImage? {
		let aspectRatio = min(
			targetSize.width / size.width,
			targetSize.height / size.height
		)

		let newSize = CGSize(
			width: size.width * aspectRatio,
			height: size.height * aspectRatio
		)

		return renderResizedImage(to: newSize)
	}

	public func resizedToFill(_ targetSize: CGSize) -> UIImage? {
		let aspectRatio = max(
			targetSize.width / size.width,
			targetSize.height / size.height
		)

		let scaledSize = CGSize(
			width: size.width * aspectRatio,
			height: size.height * aspectRatio
		)

		let renderer = UIGraphicsImageRenderer(size: targetSize)
		return renderer.image { _ in
			let origin = CGPoint(
				x: (targetSize.width - scaledSize.width) * 0.5,
				y: (targetSize.height - scaledSize.height) * 0.5
			)
			draw(in: CGRect(origin: origin, size: scaledSize))
		}
	}

	public func resized(toWidth width: CGFloat) -> UIImage? {
		let scale = width / size.width
		let newHeight = size.height * scale
		let newSize = CGSize(width: width, height: newHeight)
		return renderResizedImage(to: newSize)
	}

	private func renderResizedImage(to size: CGSize) -> UIImage? {
		let renderer = UIGraphicsImageRenderer(size: size)
		return renderer.image { _ in
			draw(in: CGRect(origin: .zero, size: size))
		}
	}
}
