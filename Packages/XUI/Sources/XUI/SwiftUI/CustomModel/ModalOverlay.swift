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
    private let onClose: () -> Void

    public init(
        _ alignment: Alignment,
        from edge: Edge,
        allowsBackgroundTap: Bool = true,
        @ViewBuilder _ content: @escaping () -> Content,
        onClose: @escaping () -> Void
    ) {
        self.alignment = alignment
        self.edge = edge
        self.allowsBackgroundTap = allowsBackgroundTap
        self.content = content
        self.onClose = onClose
    }

    public var body: some View {
        ModalContentView(alignment, allowsBackgroundTap: allowsBackgroundTap, {
            content()
        }, onClose: onClose)
            .transition(
                .asymmetric(
                    insertion: .modal(edge: edge, curve: .easeOut(duration: 0.5)),
                    removal: .modal(edge: edge, curve: .easeIn(duration: 0.4))
                )
            )
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
                Color.clear
                    .contentShape(ContainerRelativeShape())
                    .ignoresSafeArea()
                    .backgroundExtensionEffect()
                    .gesture(backgroundTapGesture)
            } else {
                Color.clear.hidden()
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
