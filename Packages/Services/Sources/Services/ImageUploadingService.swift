//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import FirebaseStorage
import SwiftUI
import UIKit
import UniformTypeIdentifiers

public struct ImageUploadingService: Sendable {
    public enum Path {
        case user(uid: String)
        case group(groupID: String)
        case conversation(conID: String, attachmentID: String)

        var path: String {
            switch self {
            case .user:
                "users"
            case .group:
                "groups"
            case .conversation:
                "conversations"
            }
        }

        var childPath: String {
            switch self {
            case let .user(uid):
                uid.storagePathComponent
            case let .group(groupID):
                groupID.storagePathComponent
            case let .conversation(conID, attachmentID):
                conID.storagePathComponent + "/" + attachmentID.storagePathComponent
            }
        }
    }

    public init() {}

    public func uploadImage(
        _ image: UIImage,
        size: CGSize?,
        to path: Path,
        onProgress: (@Sendable (Progress?) -> Void)? = nil
    ) async throws
        -> URL {
        let mediaManager = MediaManager.shared

        let uploadingImage: UIImage =
            if let size, let resizedImage = image.resizedToFill(size) {
                resizedImage
            } else {
                image
            }
        let data = try mediaManager.createData(from: uploadingImage)

        let reference = Storage.storage()
            .reference(withPath: path.path)
            .child(path.childPath)

        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        _ = try await reference.putDataAsync(
            data,
            metadata: metadata,
            onProgress: onProgress
        )
        return try await reference.downloadURL()
    }

    public func uploadFile(
        _ url: URL,
        to path: Path,
        onProgress: (@Sendable (Progress?) -> Void)? = nil
    ) async throws -> URL {
        let reference = Storage.storage()
            .reference(withPath: path.path)
            .child(path.childPath)
        let metadata = StorageMetadata()
        metadata.contentType = contentType(for: url)
        _ = try await reference.putFileAsync(from: url, metadata: metadata, onProgress: onProgress)
        return try await reference.downloadURL()
    }

    private func contentType(for fileURL: URL) -> String {
        let ext = fileURL.pathExtension
        if ext.isEmpty {
            return "application/octet-stream"
        }
        return UTType(filenameExtension: ext)?.preferredMIMEType ?? "application/octet-stream"
    }
}

private extension String {
    var storagePathComponent: String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.")
        let scalars = unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
        return String(scalars)
    }
}

public extension UIImage {
    func resizedToFit(in targetSize: CGSize) -> UIImage? {
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

    func resizedToFill(_ targetSize: CGSize) -> UIImage? {
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

    func resized(toWidth width: CGFloat) -> UIImage? {
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
