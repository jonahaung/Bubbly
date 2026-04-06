//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// private enum Phase: Equatable {
//	case idle
//	case loading(Task<Void, Never>)
//	case success
//	case failure(Error)
//
//	static func == (lhs: Phase, rhs: Phase) -> Bool {
//		switch (lhs, rhs) {
//		case (.idle, .idle):
//			return true
//		case (.loading, .loading):
//			return true
//		case (.success, .success):
//			return true
//		case (.failure, .failure):
//			return true
//		default:
//			return false
//		}
//	}
// }
//
// @MainActor
// public struct AsyncButton<Label: View>: View {
//
//	private let role: ButtonRole?
//	private let options: AsyncButtonOptions
//	private let transaction: Transaction
//	private let action: () async throws -> Void
//	private let label: () -> Label
//
//	@State private var phase: Phase = .idle
//	@State private var tint: Color?
//	@State private var showingError = false
//	@State private var localizedError: AnyLocalizedError?
//
//	private var isLoading: Bool {
//		if case .loading = phase { return true }
//		return false
//	}
//
//	public var body: some View {
//		Button(role: role) {
//			trigger()
//		} label: {
//			label()
//				.opacity(showProgress ? 0 : 1)
//				.overlay {
//					if showProgress {
//						ProgressView().controlSize(.mini)
//					}
//				}
//		}
//		.disabled(disableButton)
//		.animation(transaction.animation, value: phase)
//		.tint(tint)
//		.alert(isPresented: $showingError, error: localizedError) { _ in
//			Button(role: .cancel) {}
//		} message: { error in
//			Text(error.failureReason ??
//				 error.recoverySuggestion ??
//				 "An unexpected error occurred.")
//		}
//	}
//
//	private var showProgress: Bool {
//		options.contains(.showProgressViewOnLoading) && isLoading
//	}
//
//	private var disableButton: Bool {
//		options.contains(.disableButtonOnLoading) && isLoading
//	}
//
//	private func trigger() {
//		if options.contains(.disallowParallelOperations), isLoading {
//			return
//		}
//
//		let task = Task {
//			do {
//				try await action()
//				await handleSuccess()
//			} catch {
//				await handleFailure(error)
//			}
//		}
//
//		phase = .loading(task)
//	}
//
//	private func handleSuccess() {
//		phase = .success
//
//		if options.contains(.enableTintFeedback) {
//			animateTint(.green)
//		}
//	}
//
//	private func handleFailure(_ error: Error) {
//		phase = .failure(error)
//
//		if options.contains(.enableTintFeedback) {
//			animateTint(.red)
//		}
//
//		if options.contains(.showAlertOnError) {
//			let localized = error as? LocalizedError ?? UnlocalizedError(error: error)
//			localizedError = AnyLocalizedError(erasing: localized)
//			showingError = true
//		}
//	}
//
//	private func animateTint(_ color: Color) {
//		withAnimation(.linear(duration: 0.1)) {
//			tint = color
//		}
//
//		Task {
//			try? await Task.sleep(for: .seconds(1.5))
//			withAnimation(.linear(duration: 0.2)) {
//				tint = nil
//			}
//		}
//	}
//
//	public init(
//		role: ButtonRole? = nil,
//		options: AsyncButtonOptions = .automatic,
//		transaction: Transaction = .withoutAnimation,
//		action: @escaping () async throws -> Void,
//		@ViewBuilder label: @escaping () -> Label
//	) {
//		self.role = role
//		self.options = options
//		self.transaction = transaction
//		self.action = action
//		self.label = label
//	}
// }
import SwiftUI
import Pow

public struct AsyncButton<Label: View>: View {
	private var action: () async throws -> Void
	private var options: Set<AsyncButtonOption>
	@ViewBuilder private var label: () -> Label

	@State private var isDisabled = false

	public var body: some View {
		Button {
			Task {
				do {
					try await action()
				} catch {
					ToastPresenter.show(error.localizedDescription, allowsBackgroundTap: true)
				}
			}
		} label: {
			label()
		}
	}

	public init(
		action: @escaping () async throws -> Void,
		options: Set<AsyncButtonOption> = .allCases,
		@ViewBuilder label: @escaping () -> Label
	) {
		self.action = action
		self.options = options
		self.label = label
	}
}

public enum AsyncButtonOption: CaseIterable {
	case disableButton
	case showProgressView
}
extension AsyncButton where Label == Text {
	public init(
		_ title: String,
		options: Set<AsyncButtonOption> = .allCases,
		action: @escaping () async throws -> Void
	) {
		self.init(action: action) {
			Text(title)
		}
	}
}
extension AsyncButton where Label == Image {
	public init(
		systemImageName: String,
		options: Set<AsyncButtonOption> = .allCases,
		action: @escaping () async throws -> Void
	) {
		self.init(action: action) {
			Image(systemName: systemImageName)
		}
	}
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
extension Set where Element == AsyncButtonOption {
	public static var allCases: Self {
		.init(Element.allCases)
	}
}
