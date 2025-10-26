//
//  AsyncButton.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 29/1/23.
//

import SwiftUI

/// A button that handles asynchronous operations with proper state management and error handling.
public struct AsyncButton<Label: View>: View {

	public typealias Action = @Sendable () async throws -> Void
	public typealias ErrorAction = @Sendable (Error) -> Void
	public typealias CompletionAction = @Sendable () -> Void

	// MARK: - Private Properties

	private let action: Action
	private let label: () -> Label
	private let onFinish: CompletionAction?
	private let onError: ErrorAction?
	private let role: ButtonRole?
	private let animationDuration: TimeInterval
	private let hapticFeedbackEnabled: Bool

	@State private var task: Task<Void, Never>?
	@State private var isRunning = false
	@State private var hasCompleted = false

	// Haptic feedback generator - lazy to avoid unnecessary initialization
	private var feedbackGenerator: UIImpactFeedbackGenerator? {
		hapticFeedbackEnabled ? UIImpactFeedbackGenerator(style: .light) : nil
	}

	// MARK: - Initialization

	public init(
		role: ButtonRole? = nil,
		animationDuration: TimeInterval = 0.3,
		hapticFeedbackEnabled: Bool = true,
		action: @escaping Action,
		@ViewBuilder label: @escaping () -> Label,
		onFinish: CompletionAction? = nil,
		onError: ErrorAction? = nil
	) {
		self.role = role
		self.animationDuration = animationDuration
		self.hapticFeedbackEnabled = hapticFeedbackEnabled
		self.action = action
		self.label = label
		self.onFinish = onFinish
		self.onError = onError

		// Prepare haptic feedback if enabled
		if hapticFeedbackEnabled {
			feedbackGenerator?.prepare()
		}
	}

	// MARK: - Body

	public var body: some View {
		Button(role: role) {
			triggerAction()
		} label: {
			label()
				.scaleEffect(isRunning ? 0.7 : 1.0)
				.opacity(isRunning ? 0.8 : 1.0)
				.animation(.easeInOut(duration: animationDuration), value: isRunning)
		}
		.disabled(isRunning)
		.onDisappear {
			cancelTask()
		}
		.accessibilityElement(children: .combine)
		.accessibilityLabel(accessibilityLabel)
		.accessibilityHint(accessibilityHint)
		.accessibilityAddTraits(.isButton)
		.accessibilityAddTraits(isRunning ? .isSelected : [])
	}
}

// MARK: - Private Implementation

private extension AsyncButton {

	var accessibilityLabel: Text {
		if isRunning {
			return Text("Processing")
		} else if hasCompleted {
			return Text("Completed")
		} else {
			return Text("Button")
		}
	}

	var accessibilityHint: Text {
		if isRunning {
			return Text("Operation in progress")
		} else {
			return Text("Double tap to activate")
		}
	}

	private func triggerAction() {
		guard !isRunning else { return }

		isRunning = true
		hasCompleted = false

		// Cancel any existing task before starting a new one
		cancelTask()

		task = Task {
			await executeAsyncAction()
		}
	}

	func cancelTask() {
		task?.cancel()
		task = nil
	}

	@MainActor
	private func executeAsyncAction() async {
		// Provide haptic feedback
		if hapticFeedbackEnabled {
			feedbackGenerator?.impactOccurred()
		}

		do {
			// Small delay to allow animation to show
			if animationDuration > 0 {
				try await Task.sleep(nanoseconds: UInt64(animationDuration * 1_000_000_000))
			}

			// Execute the main action
			try await executeActionOnBackground()

			// Mark as completed and reset state
			await handleCompletion()

		} catch {
			await handleError(error)
		}
	}

	@concurrent private func executeActionOnBackground() async throws {
		try await action()
	}

	@MainActor
	private func handleCompletion() async {
		isRunning = false
		hasCompleted = true

		// Execute completion handler if provided
		onFinish?()

		// Reset completion state after a brief period
		Task {
			try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
			await MainActor.run {
				hasCompleted = false
			}
		}
	}

	@MainActor
	private func handleError(_ error: Error) async {
		isRunning = false

		// Only propagate non-cancellation errors
		if !error.isCancellationError {
			onError?(error)
		}
	}
}

// MARK: - Convenience Initializers

public extension AsyncButton where Label == Text {
	init(
		_ title: LocalizedStringKey,
		role: ButtonRole? = nil,
		animationDuration: TimeInterval = 0.15,
		hapticFeedbackEnabled: Bool = true,
		action: @escaping Action,
		onFinish: CompletionAction? = nil,
		onError: ErrorAction? = nil
	) {
		self.init(
			role: role,
			animationDuration: animationDuration,
			hapticFeedbackEnabled: hapticFeedbackEnabled,
			action: action,
			label: { Text(title) },
			onFinish: onFinish,
			onError: onError
		)
	}

	init(
		_ title: String,
		role: ButtonRole? = nil,
		animationDuration: TimeInterval = 0.15,
		hapticFeedbackEnabled: Bool = true,
		action: @escaping Action,
		onFinish: CompletionAction? = nil,
		onError: ErrorAction? = nil
	) {
		self.init(
			role: role,
			animationDuration: animationDuration,
			hapticFeedbackEnabled: hapticFeedbackEnabled,
			action: action,
			label: { Text(title) },
			onFinish: onFinish,
			onError: onError
		)
	}
}

// MARK: - Error Extension

private extension Error {
	var isCancellationError: Bool {
		(self as? CancellationError) != nil
	}
}

// MARK: - Preview

#Preview {
	VStack(spacing: 20) {
		AsyncButton("Tap Me") {
			try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
			print("Action completed!")
		} onFinish: {
			print("Finished handler called")
		} onError: { error in
			print("Error occurred: \(error)")
		}

		AsyncButton("No Haptics", hapticFeedbackEnabled: false) {
			try await Task.sleep(nanoseconds: 1_000_000_000)
		}

		AsyncButton(role: .destructive) {
			try await Task.sleep(nanoseconds: 1_500_000_000)
		} label: {
			Label("Delete", systemImage: "trash")
		}
	}
	.padding()
}
