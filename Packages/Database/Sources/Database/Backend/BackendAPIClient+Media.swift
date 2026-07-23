import Foundation

public extension BackendAPIClient {
    enum MediaPath: Sendable {
        case group(groupID: String)
        case conversation(conversationID: String, attachmentID: String)

        fileprivate var components: [String] {
            switch self {
            case let .group(groupID):
                ["groups", groupID, "photo"]
            case let .conversation(conversationID, attachmentID):
                ["conversations", conversationID, attachmentID]
            }
        }
    }

    func uploadMedia(data: Data, contentType: String, to path: MediaPath) async throws -> URL {
        try validateMedia(data: data, contentType: contentType)
        let response = try await executor.requiredResponse(
            method: "PUT",
            path: ["v1", "media"] + path.components,
            body: .data(data),
            contentType: contentType
        )
        return try mediaURL(from: response)
    }

    func uploadMedia(fileURL: URL, contentType: String, to path: MediaPath) async throws -> URL {
        try validateMedia(fileURL: fileURL, contentType: contentType)
        let response = try await executor.requiredResponse(
            method: "PUT",
            path: ["v1", "media"] + path.components,
            body: .file(fileURL),
            contentType: contentType
        )
        return try mediaURL(from: response)
    }

    func deleteMedia(at path: MediaPath) async throws {
        _ = try await executor.send(method: "DELETE", path: ["v1", "media"] + path.components)
    }

    private func mediaURL(from data: Data) throws -> URL {
        let response = try executor.decode(MediaUploadResponse.self, from: data)
        guard let url = URL(string: response.url),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            throw BackendAPIError.invalidResponse
        }
        return url
    }

    private func validateMedia(data: Data, contentType: String) throws {
        guard !data.isEmpty, data.count <= 10 * 1_024 * 1_024 else {
            throw BackendAPIError.invalidRequest("The image must be between 1 byte and 10 MB.")
        }
        guard Self.isSupportedMediaImage(data: data, contentType: contentType) else {
            throw BackendAPIError.invalidRequest("The image format is unsupported.")
        }
    }

    private func validateMedia(fileURL: URL, contentType: String) throws {
        guard fileURL.isFileURL else {
            throw BackendAPIError.invalidRequest("The image URL must reference a local file.")
        }
        let values = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard values.isRegularFile == true,
              let size = values.fileSize,
              size > 0,
              size <= 10 * 1_024 * 1_024 else {
            throw BackendAPIError.invalidRequest("The image must be between 1 byte and 10 MB.")
        }
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }
        let prefix = try handle.read(upToCount: 12) ?? Data()
        guard Self.isSupportedMediaImage(data: prefix, contentType: contentType) else {
            throw BackendAPIError.invalidRequest("The image format is unsupported.")
        }
    }

    private static func isSupportedMediaImage(data: Data, contentType: String) -> Bool {
        switch contentType.lowercased() {
        case "image/png":
            data.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        case "image/jpeg":
            data.starts(with: [0xFF, 0xD8, 0xFF])
        case "image/webp":
            data.count >= 12
                && data.prefix(4) == Data("RIFF".utf8)
                && data.dropFirst(8).prefix(4) == Data("WEBP".utf8)
        default:
            false
        }
    }
}

private struct MediaUploadResponse: Decodable, Sendable {
    let url: String
}
