
import Foundation

public enum OpaqueValue: Equatable {
    public struct PropertyKey: CodingKey, Hashable {
        public var stringValue: String
        public var intValue: Int?

        public init?(stringValue: String) {
            self.stringValue = stringValue
        }

        public init?(intValue: Int) {
            self.intValue = intValue
            stringValue = String(intValue)
        }
    }

    case object([PropertyKey: OpaqueValue])
    case array([OpaqueValue])
    case string(String)
    case number(Double)
    case boolean(Bool)
    case null
}

extension OpaqueValue: Encodable {
    public func encode(to encoder: any Encoder) throws {
        switch self {
        case let .object(values):
            var container = encoder.container(keyedBy: PropertyKey.self)
            for (key, value) in values {
                try container.encode(value, forKey: key)
            }
        case let .array(values):
            var container = encoder.unkeyedContainer()
            for value in values {
                try container.encode(value)
            }
        case let .string(value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case let .number(value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case let .boolean(value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}

// MARK: OpaqueValue+Decodable

extension OpaqueValue: Decodable {
    public init(from decoder: any Decoder) throws {
        if let container = try? decoder.container(keyedBy: PropertyKey.self) {
            var values = [PropertyKey: OpaqueValue]()
            for key in container.allKeys {
                values[key] = try container.decode(OpaqueValue.self, forKey: key)
            }
            self = .object(values)
        } else if var container = try? decoder.unkeyedContainer() {
            var values = [OpaqueValue]()
            while !container.isAtEnd {
                try values.append(container.decode(OpaqueValue.self))
            }
            self = .array(values)
        } else {
            let container = try decoder.singleValueContainer()
            if let value = try? container.decode(String.self) {
                self = .string(value)
            } else if let value = try? container.decode(Double.self) {
                self = .number(value)
            } else if let value = try? container.decode(Bool.self) {
                self = .boolean(value)
            } else {
                guard container.decodeNil() else {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Data unrecognizable",
                    )
                }
                self = .null
            }
        }
    }
}
