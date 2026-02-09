//
//  QueryValidationMode.swift
//  Services
//
//  Created by Aung Ko Min on 29/1/26.
//

import Foundation

public enum QueryValidationMode: Sendable, Equatable {
	/// Ignore unknown params.
	case permissive
	/// Reject unknown params (recommended for security-sensitive apps).
	case strict
}
