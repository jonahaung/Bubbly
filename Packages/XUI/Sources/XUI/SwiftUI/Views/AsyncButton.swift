//
//  AsyncButton.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 29/1/23.
//

import SwiftUI

public struct AsyncButton<Label: View>: View {

	public typealias Action = @Sendable () async throws -> Void
	public typealias ErrorAction = @Sendable (Error) -> Void

	private let action: Action
	private let label: () -> Label
	private let onFinish: Action?
	private let onError: ErrorAction?
	private let role: ButtonRole?
	private let generator = UIImpactFeedbackGenerator(style: .light)

	@State private var task: Task<Void, Never>?
	@State private var isRunning = false

	public init(
		role: ButtonRole? = nil,
		action: @escaping Action,
		@ViewBuilder label: @escaping () -> Label,
		onFinish: Action? = nil,
		onError: ErrorAction? = nil
	) {
		self.role = role
		self.action = action
		self.label = label
		self.onFinish = onFinish
		self.onError = onError
		generator.prepare()
	}

	public var body: some View {
		Button(role: role) {
			guard !isRunning else { return }
			triggerAction()
		} label: {
			label()
				.scaleEffect(isRunning ? 0.9 : 1.0, anchor: .center)
		}
		.onDisappear {
			task?.cancel()
		}
		.geometryGroup()
	}

	private func triggerAction() {
		guard !isRunning else { return }
		isRunning = true
		task = Task.detached(priority: .background) {
			await generator.impactOccurred()
			do {
				try await Task.sleep(seconds: 0.3)
				try await action()
				try await onFinish?()
				await MainActor.run {
					isRunning = false
				}
			} catch {
				if !error.isCancellationError {
					onError?(error)
				}
				await MainActor.run {
					isRunning = false
				}
			}
		}
	}
}
private extension Error {
	var isCancellationError: Bool {
		(self as? CancellationError) != nil
	}
}
