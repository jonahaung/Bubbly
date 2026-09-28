//  APIRequest+Contacts.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Shared
import Foundation

extension Request {

    struct ContactLookup: APIRequest {
        typealias Response = [Contact]
        struct Body: Encodable {
            let mobileNumbers: [String]
        }

        let method: HTTPMethod = .post
        let path: API.Path = .contacts
        let endPaths: [String] = [API.SubPath.lookup.rawValue]
        let body: HTTPRequestBody?

        init(mobileNumbers: [String]) {
            body = .encodable(Body(mobileNumbers: mobileNumbers))
        }
    }

    struct ContactUpdate<T: ContactRepresentableSendable>: APIRequest {
        typealias Response = T
        let method: HTTPMethod = .put
        let path: API.Path = .contacts
        let endPaths: [String] = [API.SubPath.put.rawValue]
        let body: HTTPRequestBody?

        init(modal: T) {
            body = .encodable(modal)
        }
    }

    struct ContactGet<T: ContactRepresentableSendable>: APIRequest {
        typealias Response = T
        let method: HTTPMethod = .get
        let path: API.Path = .contacts
        let endPaths: [String]
        init(uid: String) {
            endPaths = [uid]
        }
    }
}

extension Request {
    struct ContactUpdateProfilePhoto<T: ContactRepresentableSendable>: APIRequest {
        typealias Response = T
        let method: HTTPMethod = .put
        var contentType: String?
        let path: API.Path = .contacts
        let endPaths = ["profile_photo", "put"]
        let body: HTTPRequestBody?

        init(mdata: Data, contentType: String) throws {
            try Self.validatePhoto(data: mdata, contentType: contentType)
            self.contentType = contentType
            body = .data(mdata)
        }

        init(fileURL: URL, contentType: String) throws {
            try Self.validatePhoto(fileURL: fileURL, contentType: contentType)
            self.contentType = contentType
            body = .file(fileURL)
        }

        private static func validatePhoto(fileURL: URL, contentType: String)
            throws
        {
            guard fileURL.isFileURL else {
                throw HTTPError.invalidRequest(
                    "The profile photo URL must reference a local file."
                )
            }
            let values = try fileURL.resourceValues(forKeys: [
                .fileSizeKey, .isRegularFileKey,
            ])
            guard values.isRegularFile == true,
                let size = values.fileSize,
                size > 0,
                size <= 1_048_576
            else {
                throw HTTPError.invalidRequest(
                    "The profile photo must be between 1 byte and 1 MB."
                )
            }
            let handle = try FileHandle(forReadingFrom: fileURL)
            defer { try? handle.close() }
            let prefix = try handle.read(upToCount: 12) ?? Data()
            guard Self.isSupportedImage(data: prefix, contentType: contentType) else {
                throw HTTPError.invalidRequest(
                    "The profile photo format is unsupported."
                )
            }
        }

        private static func validatePhoto(data: Data, contentType: String)
            throws
        {
            guard !data.isEmpty, data.count <= 1_048_576 else {
                throw HTTPError.invalidRequest(
                    "The profile photo must be between 1 byte and 1 MB."
                )
            }
            guard Self.isSupportedImage(data: data, contentType: contentType) else {
                throw HTTPError.invalidRequest(
                    "The profile photo format is unsupported."
                )
            }
        }

        private static func isSupportedImage(data: Data, contentType: String)
            -> Bool
        {
            switch contentType.lowercased() {
            case "image/png":
                data.starts(with: [
                    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
                ])
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
}
