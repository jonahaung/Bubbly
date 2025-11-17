import SwiftUI

@MainActor
public struct AsyncButton<Label>: View where Label: View {
    private let role: ButtonRole?
    private let options: AsyncButtonOptions
    private let transaction: Transaction
    private let action: () async throws -> Void
    private let label: ([AsyncButtonOperation]) -> Label

    @State private var operations: [AsyncButtonOperation] = []
    @State private var showingErrorAlert = false
    @State private var localizedError: AnyLocalizedError?
    @State private var tint: Color?

    var operationIsLoading: Bool {
        operations.contains {
            if case .loading = $0 { return true }
            return false
        }
    }

    var showProgressView: Bool {
        options.contains(.showProgressViewOnLoading) && operationIsLoading
    }

    var disableButton: Bool {
        options.contains(.disableButtonOnLoading) && operationIsLoading
    }

    public var body: some View {
        Button(
            role: role,
            action: {
                if options.contains(.disallowParallelOperations) {
                    guard operationIsLoading == false else { return }
                }

                // Spawn the actual async action off the main actor.
                let actionTask = Task {
                    try await action()
                }

                // Record as loading on the main actor.
                operations.append(.loading(actionTask))

                // Consume the result; confine all state mutations to MainActor.
                Task { [options] in
                    let result = await actionTask.result

                    await MainActor.run {
                        // Replace the matching loading operation with completed; if not found, append.
                        if let idx = operations.lastIndex(where: {
                            if case let .loading(t) = $0 { return t == actionTask }
                            return false
                        }) {
                            operations[idx] = .completed(actionTask, result)
                        } else {
                            operations.append(.completed(actionTask, result))
                        }

                        if options.contains(.enableTintFeedback) {
                            withAnimation(.linear(duration: 0.1)) {
                                switch result {
                                case .success: tint = .green
                                case .failure: tint = .red
                                }
                            }
                            withAnimation(.linear(duration: 0.2).delay(1.5)) {
                                tint = nil
                            }
                        }

                        if options.contains(.showAlertOnError),
                           case let .failure(error) = result
                        {
                            let localizedError = error as? LocalizedError ?? UnlocalizedError(error: error)
                            self.localizedError = AnyLocalizedError(erasing: localizedError)
                            showingErrorAlert = true
                        }
                    }
                }
            },
            label: {
                label(operations)
                    .opacity(showProgressView ? 0 : 1)
                    .overlay {
                        if showProgressView {
                            ProgressView()
                        }
                    }
            }
        )
        .sensoryFeedback(.selection, trigger: operations.count)
        .disabled(disableButton)
        .animation(transaction.animation, value: operations)
        .tint(tint)
        .alert(isPresented: $showingErrorAlert, error: localizedError) { _ in
            Button("OK") {
                showingErrorAlert = false
            }
        } message: { error in
            if let message = error.failureReason ?? error.recoverySuggestion ?? error.helpAnchor {
                Text(message)
            }
        }
    }

    public init(
        role: ButtonRole? = nil,
        options: AsyncButtonOptions = [],
        transaction: Transaction = Transaction(),
        action: @escaping () async throws -> Void,
        @ViewBuilder label: @escaping ([AsyncButtonOperation]) -> Label
    ) {
        self.role = role
        self.options = options
        self.transaction = transaction
        self.action = action
        self.label = label
    }
}

public extension AsyncButton {
    init(
        role: ButtonRole? = nil,
        options: AsyncButtonOptions = .automatic,
        transaction: Transaction = Transaction(animation: .default),
        action: @escaping () async throws -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.init(role: role, options: options, transaction: transaction, action: action) { _ in
            label()
        }
    }
}

public extension AsyncButton where Label == Text {
    init(
        _ titleKey: LocalizedStringKey,
        role: ButtonRole? = nil,
        options: AsyncButtonOptions = .automatic,
        transaction: Transaction = Transaction(animation: .default),
        action: @escaping () async throws -> Void
    ) {
        self.init(role: role, options: options, transaction: transaction, action: action) { _ in
            Text(titleKey)
        }
    }
}

public extension AsyncButton where Label == Text {
    init(
        _ title: some StringProtocol,
        role: ButtonRole?,
        options: AsyncButtonOptions = .automatic,
        transaction: Transaction = Transaction(animation: .default),
        action: @escaping () async throws -> Void
    ) {
        self.init(role: role, options: options, transaction: transaction, action: action) { _ in
            Text(title)
        }
    }
}
