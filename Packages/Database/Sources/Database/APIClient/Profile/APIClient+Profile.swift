import Core
import Foundation

public extension HTTPClient {

    func uploadProfilePhoto(data: Data, contentType: String) async throws -> URL {
        try validatePhoto(data: data, contentType: contentType)
        let response = try await executor.requiredResponse(
            method: "PUT",
            path: ["v1", "contacts", "photo"],
            body: .data(data),
            contentType: contentType
        )
        return try profilePhotoURL(from: response)
    }

    func uploadProfilePhoto(fileURL: URL, contentType: String) async throws -> URL {
        try validatePhoto(fileURL: fileURL, contentType: contentType)
        let response = try await executor.requiredResponse(
            method: "PUT",
            path: ["v1", "contacts", "photo"],
            body: .file(fileURL),
            contentType: contentType
        )
        return try profilePhotoURL(from: response)
    }

    func deleteProfilePhoto() async throws {
        _ = try await executor.send(method: "DELETE", path: ["v1", "contacts", "photo"])
    }

    private func profilePhotoURL(from data: Data) throws -> URL {
        let model = try executor.decode(CurrentUserModel.self, from: data)
        guard let url = URL(string: model.photoURL),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host != nil
        else {
            throw HTTPError.invalidResponse
        }
        return url
    }

    private func validatePhoto(data: Data, contentType: String) throws {
        guard !data.isEmpty, data.count <= 1_048_576 else {
            throw HTTPError.invalidRequest("The profile photo must be between 1 byte and 1 MB.")
        }
        guard Self.isSupportedImage(data: data, contentType: contentType) else {
            throw HTTPError.invalidRequest("The profile photo format is unsupported.")
        }
    }

    private func validatePhoto(fileURL: URL, contentType: String) throws {
        guard fileURL.isFileURL else {
            throw HTTPError.invalidRequest("The profile photo URL must reference a local file.")
        }
        let values = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard values.isRegularFile == true,
            let size = values.fileSize,
            size > 0,
            size <= 1_048_576
        else {
            throw HTTPError.invalidRequest("The profile photo must be between 1 byte and 1 MB.")
        }
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }
        let prefix = try handle.read(upToCount: 12) ?? Data()
        guard Self.isSupportedImage(data: prefix, contentType: contentType) else {
            throw HTTPError.invalidRequest("The profile photo format is unsupported.")
        }
    }

    private static func isSupportedImage(data: Data, contentType: String) -> Bool {
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
