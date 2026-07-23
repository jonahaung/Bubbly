import Core
import Foundation

public extension BackendAPIClient {
    func currentProfile() async throws -> CurrentUserModel? {
        guard let data = try await executor.send(
            method: "GET",
            path: ["v1", "profile"],
            allowsNotFound: true
        ) else {
            return nil
        }
        return try executor.decode(CurrentUserModel.self, from: data)
    }

    @discardableResult
    func updateProfile(_ model: CurrentUserModel) async throws -> CurrentUserModel {
        let body = ProfileUpdateRequest(model)
        try validate(body)
        let data = try await executor.requiredResponse(
            method: "PUT",
            path: ["v1", "profile"],
            body: .data(try executor.encode(body)),
            contentType: "application/json"
        )
        return try executor.decode(CurrentUserModel.self, from: data)
    }

    func updatePushToken(_ pushToken: String) async throws {
        guard !pushToken.isEmpty, pushToken.count <= 4_096 else {
            throw BackendAPIError.invalidRequest("The push token is invalid.")
        }
        _ = try await executor.send(
            method: "PATCH",
            path: ["v1", "profile", "push-token"],
            body: .data(try executor.encode(PushTokenUpdateRequest(pushToken: pushToken))),
            contentType: "application/json"
        )
    }

    func uploadProfilePhoto(data: Data, contentType: String) async throws -> URL {
        try validatePhoto(data: data, contentType: contentType)
        let response = try await executor.requiredResponse(
            method: "PUT",
            path: ["v1", "profile", "photo"],
            body: .data(data),
            contentType: contentType
        )
        return try profilePhotoURL(from: response)
    }

    func uploadProfilePhoto(fileURL: URL, contentType: String) async throws -> URL {
        try validatePhoto(fileURL: fileURL, contentType: contentType)
        let response = try await executor.requiredResponse(
            method: "PUT",
            path: ["v1", "profile", "photo"],
            body: .file(fileURL),
            contentType: contentType
        )
        return try profilePhotoURL(from: response)
    }

    func deleteProfilePhoto() async throws {
        _ = try await executor.send(method: "DELETE", path: ["v1", "profile", "photo"])
    }

    private func profilePhotoURL(from data: Data) throws -> URL {
        let model = try executor.decode(CurrentUserModel.self, from: data)
        guard let url = URL(string: model.photoURL),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            throw BackendAPIError.invalidResponse
        }
        return url
    }

    private func validate(_ profile: ProfileUpdateRequest) throws {
        guard profile.name.trimmingCharacters(in: .whitespacesAndNewlines).count <= 100,
              profile.mobile.isEmpty || Self.isE164ProfileMobile(profile.mobile),
              profile.pushToken.count <= 4_096,
              profile.publicKeyString.count <= 8_192 else {
            throw BackendAPIError.invalidRequest("The profile contains invalid values.")
        }
    }

    private func validatePhoto(data: Data, contentType: String) throws {
        guard !data.isEmpty, data.count <= 1_048_576 else {
            throw BackendAPIError.invalidRequest("The profile photo must be between 1 byte and 1 MB.")
        }
        guard Self.isSupportedImage(data: data, contentType: contentType) else {
            throw BackendAPIError.invalidRequest("The profile photo format is unsupported.")
        }
    }

    private func validatePhoto(fileURL: URL, contentType: String) throws {
        guard fileURL.isFileURL else {
            throw BackendAPIError.invalidRequest("The profile photo URL must reference a local file.")
        }
        let values = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard values.isRegularFile == true,
              let size = values.fileSize,
              size > 0,
              size <= 1_048_576 else {
            throw BackendAPIError.invalidRequest("The profile photo must be between 1 byte and 1 MB.")
        }
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }
        let prefix = try handle.read(upToCount: 12) ?? Data()
        guard Self.isSupportedImage(data: prefix, contentType: contentType) else {
            throw BackendAPIError.invalidRequest("The profile photo format is unsupported.")
        }
    }

    private static func isE164ProfileMobile(_ value: String) -> Bool {
        guard value.count >= 9, value.count <= 16, value.first == "+" else {
            return false
        }
        let digits = value.dropFirst()
        return digits.first != "0"
            && digits.unicodeScalars.allSatisfy { (48 ... 57).contains($0.value) }
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
