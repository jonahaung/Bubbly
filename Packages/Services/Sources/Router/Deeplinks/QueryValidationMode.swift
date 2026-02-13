import Foundation

public enum QueryValidationMode: Sendable, Equatable {
	/// Ignore unknown params.
	case permissive
	/// Reject unknown params (recommended for security-sensitive apps).
	case strict
}
