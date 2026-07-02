//  ModalOverlay.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public struct ModalOverlay<Content: View>: View {
    private let alignment: Alignment
    private let edge: Edge
    private let allowsBackgroundTap: Bool
    @ViewBuilder private let content: () -> Content
    @Environment(\.dismiss) private var dismiss
   
    @State private var showContent = false
    public init(
        _ alignment: Alignment,
        from edge: Edge,
        allowsBackgroundTap: Bool = true,
        @ViewBuilder _ content: @escaping () -> Content
    ) {
        self.alignment = alignment
        self.edge = edge
        self.allowsBackgroundTap = allowsBackgroundTap
        self.content = content
    }

    public var body: some View {
        ModalContentView(alignment, allowsBackgroundTap: allowsBackgroundTap, {
            if showContent {
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                    .transition(
                        .asymmetric(
                            insertion: .modal(edge: edge, curve: .easeOutExponential),
                            removal: .modal(edge: edge, curve: .easeInExponential)
                        )
                    )
            }
        }, onClose: onClose)
        .onAppear {
            showContent = true
        }
        .statusBarHidden()
    }
    
    private func onClose() {
        showContent = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withTransaction(\.disablesAnimations, true) {
                dismiss()
            }
        }
    }
}

public struct ModalContentView<Content: View>: View {
    private let alignment: Alignment
    private let allowsBackgroundTap: Bool
    @ViewBuilder private let content: () -> Content
    private let onClose: () -> Void
    @Environment(\.dismiss) private var dismiss
    public init(
        _ alignment: Alignment,
        allowsBackgroundTap: Bool,
        @ViewBuilder _ content: @escaping () -> Content,
        onClose: @escaping () -> Void
    ) {
        self.alignment = alignment
        self.allowsBackgroundTap = allowsBackgroundTap
        self.content = content
        self.onClose = onClose
    }

    public var body: some View {
        ZStack(alignment: alignment) {
            if allowsBackgroundTap {
                Color.white.opacity(0.00001)
                    .contentShape(ContainerRelativeShape())
                    .ignoresSafeArea()
                    .backgroundExtensionEffect()
                    .gesture(backgroundTapGesture)
            }
            content()
        }
    }

    private var backgroundTapGesture: some Gesture {
        TapGesture().onEnded {
            onClose()
        }
    }
}
