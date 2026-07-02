import SwiftUI

//public enum AsyncButtonOption: Hashable, CaseIterable {
//    case disableButton
//    case tintFeedback
//
//    public static var all: Set<Self> { Set(allCases) }
//}
//
//@MainActor
//public struct AsyncButton<Label: View>: View {
//
//    // MARK: - Phase
//
//    private enum Phase: Equatable {
//        case idle
//        case loading
//        case success
//        case failure
//    }
//
//    // MARK: - Properties
//
//    private let action: () async throws -> Void
//    private let options: Set<AsyncButtonOption>
//    @ViewBuilder private let label: () -> Label
//
//    @State private var phase: Phase = .idle
//    @State private var currentTask: Task<Void, Never>?
//    @State private var tint: Color?
//
//    private var isLoading: Bool { phase == .loading }
//
//    // MARK: - Body
//
//    public var body: some View {
//        Button(action: trigger) {
//            label()
//        }
//        .disabled(disableButton)
//        .tint(tint)
//        .animation(.smooth(duration: 0.25), value: phase)
//        .geometryGroup()
//    }
//
//    // MARK: - Actions
//
//    private func trigger() {
//        guard !isLoading || !options.contains(.disableButton) else { return }
//
//        // Cancel any in-flight task before starting a new one
//        currentTask?.cancel()
//
//        currentTask = Task {
//            do {
//                try await action()
//                handleSuccess()
//            } catch {
//                handleFailure(error)
//            }
//        }
//
//        phase = .loading
//    }
//
//    private func handleSuccess() {
//        phase = .success
//        if options.contains(.tintFeedback) { animateTint(.blue) }
//    }
//
//    private func handleFailure(_ error: Error) {
//        phase = .failure
//        ToastPresenter.show(error.localizedDescription, allowsBackgroundTap: true)
//        if options.contains(.tintFeedback) { animateTint(.red) }
//    }
//
//    private var disableButton: Bool {
//        options.contains(.disableButton) && isLoading
//    }
//
//    private func animateTint(_ color: Color) {
//        withAnimation(.linear(duration: 0.12)) { tint = color }
//        Task {
//            try? await Task.sleep(for: .seconds(1.2))
//            withAnimation(.easeOut(duration: 0.25)) { tint = nil }
//        }
//    }
//
//    // MARK: - Init
//
//    public init(
//        options: Set<AsyncButtonOption> = AsyncButtonOption.all,
//        action: @escaping () async throws -> Void,
//        @ViewBuilder label: @escaping () -> Label
//    ) {
//        self.options = options
//        self.action = action
//        self.label = label
//    }
//}
////