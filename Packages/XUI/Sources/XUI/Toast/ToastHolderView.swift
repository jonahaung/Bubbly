//  ToastHolderView.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

struct ToastHolderView: View {

    let toast: Toast
    @State private var showContent = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.white.opacity(0.00001)
                .contentShape(.rect)
                .gesture(backgroundTapGesture)
            if showContent {
                let content = toast.node.eraseToNode()
                    .lineHeight(.multiple(factor: 1.1))
                    .padding(16)
                    ._onButtonGesture(
                        pressing: { pressing in
                            onClose(true)
                        },
                        perform: {

                        }
                    )
                switch toast.style {
                case .notification:
                    content
                        .glassEffect(
                            .regular.interactive(),
                            in: .containerRelative
                        )
                        .runningBorder(lineWidth: 2, cornerRadius: 7)
                        .containerShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 4)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: toast.style.alignment
                        )
                        .transition(
                            .asymmetric(
                                insertion: .modal(
                                    edge: toast.style.edge,
                                    curve: .easeOutExponential
                                ),
                                removal: .modal(
                                    edge: toast.style.edge,
                                    curve: .easeInExponential
                                )
                            )
                        )
                case .alert:
                    content
                        .background(.regularMaterial, in: .containerRelative)
                        .containerShape(.rect)
                        .padding(4)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: toast.style.alignment
                        )
                        .transition(
                            .asymmetric(
                                insertion: .modal(
                                    edge: toast.style.edge,
                                    curve: .easeOutExponential
                                ),
                                removal: .modal(
                                    edge: toast.style.edge,
                                    curve: .easeInExponential
                                )
                            )
                        )
                }
            }
        }
        .font(Typography.system.callout.leading(.tight))
        .onAppear {
            showContent = true
            Task.detached {
                try? await Task.sleep(seconds: toast.duration)
                Task { @MainActor in
                    onClose(false)
                }
            }
        }
        .presentationBackground(.clear)
        .presentationBackgroundInteraction(.disabled)
        .colorScheme(toast.style == .alert ? .dark : .light)
    }

    private var backgroundTapGesture: some Gesture {
        DragGesture(minimumDistance: 0).onEnded { _ in
            onClose(false)
        }
    }
    private func onClose(_ performAction: Bool) {
        guard showContent else { return }
        showContent = false
        Task.detached {
            try? await Task.sleep(seconds: 0.5)
            Task { @MainActor in
                withTransaction(\.disablesAnimations, true) {
                    dismiss()
                    if performAction {
                        toast.action?()
                    }
                }
            }
        }
    }
}
