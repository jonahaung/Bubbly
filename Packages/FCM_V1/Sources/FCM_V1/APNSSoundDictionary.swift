//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

public struct APNSSoundDictionary: Codable, Equatable {
    public let critical: Int
    public let name: String
    public let volume: Double

    /// - Parameters:
    ///   - isCritical: Set to true to enable the critical alert.
    ///   - name: The app’s path to a sound file.
    ///   - volume: The volume for the critical alert’s sound. Value must be between 0.0 (silent) and 1.0 (full volume).
    public init(
        isCritical: Bool,
        name: String,
        volume: Double
    ) {
        critical = isCritical ? 1 : 0
        self.name = name
        self.volume = volume
    }
}

public struct APNSSoundType: Codable, Equatable {

    private enum Base: Codable, Equatable {
        case normal(String)
        case critical(APNSSoundDictionary)
    }

    private var base: Base

    public nonisolated(unsafe) static let none: APNSSoundType? = nil

    private init(_ base: Base) {
        self.base = base
    }

    public static func normal(_ soundFileName: String) -> APNSSoundType {
        .init(.normal(soundFileName))
    }

    public static func critical(_ dictionary: APNSSoundDictionary) -> APNSSoundType {
        .init(.critical(dictionary))
    }
}

extension APNSSoundType {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch base {
        case let .normal(string):
            try container.encode(string)
        case let .critical(dictionary):
            try container.encode(dictionary)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let dictionary = try? container.decode(APNSSoundDictionary.self) {
            self = .init(.critical(dictionary))
        } else {
            self = try .init(.normal(container.decode(String.self)))
        }
    }
}
