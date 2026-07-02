import Foundation
public struct DeliveryFailure: Sendable, Equatable, Hashable, Codable {
    public let code: String
    public let isRetryable: Bool
    public init(code: String, isRetryable: Bool) {
        self.code = code
        self.isRetryable = isRetryable
    }
}
