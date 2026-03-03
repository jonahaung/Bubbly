//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public struct APNSError: Equatable, Sendable {

    public enum ResponseError: Error, Equatable, Sendable {
        case badRequest(ResponseErrorMessage)
    }

    public struct ResponseStruct: Codable, Sendable {
        public let reason: ResponseErrorMessage
    }

    public enum ResponseErrorMessage: String, Codable, Sendable {

        case badCollapseIdentifier = "BadCollapseId"
        case badDeviceToken = "BadDeviceToken"
        case badExpirationDate = "BadExpirationDate"
        case badMessageId = "BadMessageId"
        case badPriority = "BadPriority"
        case badTopic = "BadTopic"
        case deviceTokenNotForTopic = "DeviceTokenNotForTopic"
        case duplicateHeaders = "DuplicateHeaders"
        case idleTimeout = "IdleTimeout"
        case missingDeviceToken = "MissingDeviceToken"
        case missingTopic = "MissingTopic"
        case payloadEmpty = "PayloadEmpty"
        case topicDisallowed = "TopicDisallowed"
        case badCertificate = "BadCertificate"
        case badCertificateEnvironment = "BadCertificateEnvironment"
        case expiredProviderToken = "ExpiredProviderToken"
        case forbidden = "Forbidden"
        case invalidProviderToken = "InvalidProviderToken"
        case missingProviderToken = "MissingProviderToken"
        case badPath = "BadPath"
        case methodNotAllowed = "MethodNotAllowed"
        case unregistered = "Unregistered"
        case payloadTooLarge = "PayloadTooLarge"
        case tooManyProviderTokenUpdates = "TooManyProviderTokenUpdates"
        case tooManyRequests = "TooManyRequests"
        case internalServerError = "InternalServerError"
        case serviceUnavailable = "ServiceUnavailable"
        case shutdown = "Shutdown"
        case encodingFailed = "EncodingFailed"
        case unknown

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            self = ResponseErrorMessage(rawValue: raw) ?? .unknown
        }

        public var description: String {
            rawValue
        }
    }

    public enum SigningError: Error, Sendable {
        case invalidAuthKey
        case invalidASN1
        case certificateFileDoesNotExist
        case invalidSignatureData
    }
}
