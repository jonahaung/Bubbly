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
			return "Model unavailable: \(reason)"
		case .sessionBusy:
			return "Session is currently busy processing a request."
		case .unknown(let reason):
			return "Unknown error: \(reason)"
		}
	}

	public var recoverySuggestion: String? {
		switch self {
		case .modelUnavailable:
			return "Try enabling Apple Intelligence or restarting your device."
		case .sessionBusy:
			return "Wait until the current request finishes."
		case .unknown:
			return "Please try again later."
		}
	}
}
