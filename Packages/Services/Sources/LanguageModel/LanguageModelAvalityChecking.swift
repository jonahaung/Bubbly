//
//  LanguageModelAvalityChecking.swift
//  Services
//
//  Created by Aung Ko Min on 5/11/25.
//

import FoundationModels

public protocol LanguageModelAvalityChecking {
	func checkAvailability() throws
}

public final class SystemModelAvailabilityChecker: LanguageModelAvalityChecking {
	private let model: SystemLanguageModel

	public init(model: SystemLanguageModel = .default) {
		self.model = model
	}

	public func checkAvailability() throws {
		switch model.availability {
		case .available:
			return
		case .unavailable(let reason):
			throw LanguageModelError.modelUnavailable(String(describing: reason))
		@unknown default:
			throw LanguageModelError.modelUnavailable("Unknown model availability state.")
		}
	}
}
