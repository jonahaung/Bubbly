//
//  LanguageModelService.swift
//  Services
//
//  Created by Aung Ko Min on 2/11/25.
//
import SwiftUI
import FoundationModels

@MainActor
@Observable
public final class LanguageModelService {

	private let availabilityChecker = SystemModelAvailabilityChecker()
	private let model: SystemLanguageModel = .default
	public private(set) var session: LanguageModelSession
	public let tool: ExampleTool
	public var streamingEnabled = true
	public var error: (any Error)?
	public var isReady: Bool {
		!session.isResponding && error == nil
	}
	public init(
		role: LanguageModelRole
	) {
		let tool = ExampleTool()
		self.session = Self.makeSession(model, tools: [tool], role: role)
		self.tool = tool
	}
	private static func makeSession(
		_ model: SystemLanguageModel,
		tools: [any Tool],
		role: LanguageModelRole
	) -> LanguageModelSession {
		LanguageModelSession(
			model: model,
			tools: tools,
			instructions: role.modelInstructions
		)
	}
}

public extension LanguageModelService {
	func respond(to prompt: String) async throws -> String {
		try await session.respond(to: prompt).content
	}
	func stream(
		to prompt: String
	) async -> LanguageModelSession.ResponseStream<String>? {
		return session.streamResponse(to: prompt, generating: String.self)
	}
}
