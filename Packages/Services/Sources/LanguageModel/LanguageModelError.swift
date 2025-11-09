//
//  LanguageModelError.swift
//  Services
//
//  Created by Aung Ko Min on 5/11/25.
//

import Foundation

public enum LanguageModelError: LocalizedError, Equatable {
	case modelUnavailable(String)
	case sessionBusy
	case unknown(String)

	public var errorDescription: String? {
		switch self {
		case .modelUnavailable(let reason):
			"Model unavailable: \(reason)"
		case .sessionBusy:
			"Session is currently busy processing a request."
		case .unknown(let reason):
			"Unknown error: \(reason)"
		}
	}

	public var recoverySuggestion: String? {
		switch self {
		case .modelUnavailable:
			"Try enabling Apple Intelligence or restarting your device."
		case .sessionBusy:
			"Wait until the current request finishes."
		case .unknown:
			"Please try again later."
		}
	}
}
