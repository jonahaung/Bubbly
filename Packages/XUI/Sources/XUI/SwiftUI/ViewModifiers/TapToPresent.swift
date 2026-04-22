//  TapToPresent.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

private struct PresentSheetModifier<Destination: View>: ViewModifier {
    @ViewBuilder var destination: () -> Destination
    var onDismiss: (() -> Void)?
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                isPresented = true
            }
            .sheet(isPresented: $isPresented, onDismiss: onDismiss) {
                destination()
            }
    }
}

private struct PresentFullScreenModifier<Destination: View>: ViewModifier {
    @ViewBuilder var destination: () -> Destination
    var onDismiss: (() -> Void)?
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                withTransaction(.withoutAnimation()) {
                    isPresented = true
                }
            }
            .sheet(isPresented: $isPresented, onDismiss: onDismiss) {
                destination()
            }
    }
}

private struct PresentFullScreenWithTransitionModifier<Destination: View>: ViewModifier {
    let id: String
    @ViewBuilder var destination: () -> Destination

    @State private var isPresented = false
    @Namespace private var animation

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                isPresented = true
            }
            .matchedTransitionSource(id: id, in: animation)
            .fullScreenCover(
                isPresented: $isPresented
            ) {
                destination()
                    .statusBarHidden()
                    .presentationBackground(.ultraThinMaterial)
                    .presentationBackgroundInteraction(.enabled)
                    .navigationTransition(.zoom(sourceID: id, in: animation))
            }
    }
}

public extension View {
    func presentSheet(
        @ViewBuilder content: @escaping () -> some View,
        onDismiss: sending (() -> Void)? = nil
    ) -> some View {
        ModifiedContent(
            content: self,
            modifier: PresentSheetModifier(destination: content, onDismiss: onDismiss)
        )
    }

    func presentFullScreen(
        @ViewBuilder content: @escaping () -> some View,
        onDismiss: sending (() -> Void)? = nil
    ) -> some View {
        ModifiedContent(
            content: self,
            modifier: PresentFullScreenModifier(destination: content, onDismiss: onDismiss)
        )
    }

    func sheetWithZoomTransition(
        id: String = UUID().uuidString,
        @ViewBuilder destination: @escaping () -> some View
    ) -> some View {
        ModifiedContent(
            content: self,
            modifier: PresentFullScreenWithTransitionModifier(id: id, destination: destination)
        )
    }
}
