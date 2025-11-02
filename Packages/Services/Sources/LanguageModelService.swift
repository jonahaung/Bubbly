//
//  LanguageModelService.swift
//  Services
//
//  Created by Aung Ko Min on 2/11/25.
//
import SwiftUI
import FoundationModels

public enum ModelError: LocalizedError, Equatable {

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

public protocol ModelAvailabilityChecker {
	func checkAvailability() throws
}

public final class SystemModelAvailabilityChecker: ModelAvailabilityChecker {
	private let model: SystemLanguageModel

	public init(model: SystemLanguageModel = .default) {
		self.model = model
	}

	public func checkAvailability() throws {
		switch model.availability {
		case .available:
			return
		case .unavailable(let reason):
			throw ModelError.modelUnavailable(String(describing: reason))
		@unknown default:
			throw ModelError.modelUnavailable("Unknown model availability state.")
		}
	}
}

@MainActor
@Observable
public final class LanguageManager {

	private let availabilityChecker: ModelAvailabilityChecker
	private let model: SystemLanguageModel
	public private(set) var session: LanguageModelSession

	public var streamingEnabled = true
	public var error: (any Error)?
	public var isReady: Bool {
		!session.isResponding && error == nil
	}
	public init(
		availabilityChecker: ModelAvailabilityChecker = SystemModelAvailabilityChecker(),
		model: SystemLanguageModel = .default
	) {
		self.availabilityChecker = availabilityChecker
		self.model = model
		self.session = Self.makeSession(model: model)
	}
	public func respond(to prompt: String) async {
		do {
			try await performRespond(to: prompt)
		} catch {
			self.error = error
		}
	}

	func toggleStreaming() {
		streamingEnabled.toggle()
	}

	private func performRespond(to prompt: String) async throws {
		guard !session.isResponding else {
			throw ModelError.sessionBusy
		}

		try availabilityChecker.checkAvailability()

		if streamingEnabled {
			try await streamResponse(to: prompt)
		} else {
			try await performResponse(to: prompt)
		}
	}

	private func performResponse(to prompt: String) async throws {
		guard !Task.isCancelled else { return }
		_ = try await session.respond(to: prompt)
	}

	private func streamResponse(to prompt: String) async throws {
		let stream = session.streamResponse(to: prompt)
		for try await _ in stream {
			guard !Task.isCancelled else { break }
		}
	}
	private static func makeSession(
		model: SystemLanguageModel
	) -> LanguageModelSession {
		LanguageModelSession(
			model: model,
			instructions: Instructions {
 """
 Your job is to fulfill the user's requests.
 """
			}
		)
	}
}
