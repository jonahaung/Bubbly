//
//  PresentTransitionModifier.swift
//  XUI
//
//  Created by Aung Ko Min on 20/10/25.
//

import SwiftUI

private struct PresentTransitionModifier<Destination: View, Snapshot: View>: ViewModifier {
    @ViewBuilder var snapshot: () -> Snapshot
    @ViewBuilder var destination: () -> Destination
    @State private var canObserveFocusedFrame = false
    @State private var frame: CGRect?

    func body(content: Content) -> some View {
        content
            .background {
                if canObserveFocusedFrame {
                    Color.clear
                        .hidden()
                        .onGeometryChange(
                            for: CGRect.self,
                            of: { proxy in
                                proxy.frame(in: .global)
                            },
                            action: { _, newValue in
                                Task { @MainActor in
                                    canObserveFocusedFrame = false
                                    withTransaction(.withoutAnimation) {
                                        frame = newValue
                                    }
                                }
                            }
                        )
                }
            }
            .onLongPressGesture {
                canObserveFocusedFrame = true
            }
            .fullScreenCover(item: $frame) { frame in
                TransitionOverlayView<Destination, Snapshot>(frame: frame, snapshot: snapshot) {
                    destination()
                }
                .presentationBackgroundInteraction(.disabled)
                .presentationBackground(Color.clear)
            }
    }
}

// MARK: - Transition Overlay View

private struct TransitionOverlayView<Content: View, Snapshot: View>: View {
    let frame: CGRect
    @ViewBuilder var snapshot: () -> Snapshot
    @ViewBuilder var content: () -> Content
    @Environment(\.dismiss) private var dismiss

    @State private var isAppeared = false

    var body: some View {
        ZStack {
            blurredBackground
            snapshotView
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .onAppear(perform: handleAppear)
    }

    private var blurredBackground: some View {
        BlurredBackgroundView {
            withTransaction(.withoutAnimation) {
                dismiss()
            }
        }
        .opacity(isAppeared ? 1 : 0)
    }

    private var snapshotView: some View {
        snapshot()
            .frame(size: frame.size)
            .position(.init(x: frame.midX, y: frame.midY))
    }

    private func handleAppear() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isAppeared = true
        }
    }
}

// MARK: - Blurred Background

private struct BlurredBackgroundView: View {
    var tapAction: (() -> Void)?

    var body: some View {
        Rectangle()
            .fill(Color.systemFill)
            .glassEffect(.regular, in: .rect)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                tapAction?()
            }
            .transaction { transaction in
                transaction.disablesAnimations = true
            }
    }
}

private struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect? { nil }

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

// MARK: - Extensions

extension CGRect: @retroactive Identifiable {
    public var id: String {
        "\(origin.x)_\(origin.y)_\(size.width)_\(size.height)"
    }
}

public extension View {
    func presentTransition(
        snapshot: @escaping () -> some View,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        modifier(PresentTransitionModifier(
            snapshot: snapshot,
            destination: content
        ))
    }
}
