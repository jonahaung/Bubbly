import Foundation
import FoundationModels

/// A reusable helper class that eliminates code duplication across tool views
/// by providing a standardized pattern for executing tool operations
@MainActor
@Observable
public final class ToolExecutor {
	public private(set) var isRunning = false
	public var result: String?
	public var errorMessage: String?
	public private(set) var successMessage: String?

	public init() {}

	/// Executes a tool operation with standardized state management
	public func execute<T: Generable>(
		tool: any Tool,
		prompt: String,
		type: T.Type,
		successMessage: String? = nil,
		formatter: @Sendable @escaping (T) -> String,
		clearForm: (@MainActor @Sendable () -> Void)? = nil
	) async {
		await performExecution(successMessage: successMessage, clearForm: clearForm) { @Sendable in
			let session = LanguageModelSession(
				model: .init(useCase: .general, guardrails: .permissiveContentTransformations),
				tools: [tool]
			)
			let response = try await session.respond(to: prompt, generating: type)
			return formatter(response.content)
		}
	}

	/// Executes a tool operation using PromptBuilder
	public func executeWithPromptBuilder(
		tool: some Tool,
		successMessage: String? = nil,
		clearForm: (@MainActor @Sendable () -> Void)? = nil,
		@PromptBuilder promptBuilder: @Sendable () -> Prompt
	) async {
		await performExecution(successMessage: successMessage, clearForm: clearForm) { @Sendable in
			let session = LanguageModelSession(
				model: .init(useCase: .general, guardrails: .permissiveContentTransformations),
				tools: [tool]
			)
			let response = try await session.respond(to: promptBuilder())
			return response.content
		}
	}

	/// Executes a tool operation with a custom session configuration
	public func executeWithCustomSession(
		sessionBuilder: @Sendable () -> LanguageModelSession,
		prompt: String,
		successMessage: String? = nil,
		clearForm: (@MainActor @Sendable () -> Void)? = nil
	) async {
		await performExecution(successMessage: successMessage, clearForm: clearForm) { @Sendable in
			let session = sessionBuilder()
			let response = try await session.respond(to: Prompt(prompt))
			return response.content
		}
	}

	/// Private helper that encapsulates common state management logic
	@concurrent
	private func performExecution(
		successMessage: String? = nil,
		clearForm: (@MainActor @Sendable () -> Void)? = nil,
		operation: @Sendable () async throws -> String
	) async {
		await prepareForNewExecution()

		do {
			let result = try await operation()

			await finalizeExecution(result: result, successMessage: successMessage)

			await clearForm?()
		} catch {
			let errorMessage = FoundationModelsErrorHandler.handleError(error)
			await finalizeExecution(errorMessage: errorMessage)
		}
	}

	private func prepareForNewExecution() {
		isRunning = true
		errorMessage = nil
		successMessage = nil
		result = nil
	}

	private func finalizeExecution(result: String? = nil,
	                               successMessage: String? = nil,
	                               errorMessage: String? = nil)
	{
		isRunning = false
		self.result = result
		self.errorMessage = errorMessage
		self.successMessage = successMessage
	}

	/// Clears all state
	public func clear() {
		isRunning = false
		result = nil
		errorMessage = nil
		successMessage = nil
		isRunning = false
	}
}
