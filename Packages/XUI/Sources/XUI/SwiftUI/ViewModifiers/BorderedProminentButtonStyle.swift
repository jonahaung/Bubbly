//  BorderedProminentButtonStyle.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

private struct BorderedProminentButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(.roundedButtonStyle)
    }
}

public struct RoundedButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.background)
            .frame(height: 38.scaled)
            .frame(maxWidth: .infinity)
            .background(Color.accentColor.gradient, in: Capsule())
            .contentShape(Capsule())
            .buttonSizing(.flexible)
    }
}

public extension ButtonStyle where Self == RoundedButtonStyle {
    static var roundedButtonStyle: RoundedButtonStyle {
        RoundedButtonStyle()
    }
}

public extension View {
    func borderedProminentButtonStyle() -> some View {
        ModifiedContent(content: self, modifier: BorderedProminentButtonStyle())
    }
}

private struct BorderedProminentLightButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        HStack {
            content
        }
        .foregroundStyle(Color.systemBackground)
        .frame(height: 38.scaled)
        .buttonSizing(.flexible)
        .background(Color.secondary.gradient, in: Capsule())
    }
}

public extension View {
    func borderedProminentLightButtonStyle() -> some View {
        ModifiedContent(content: self, modifier: BorderedProminentLightButtonStyle())
    }
}

private struct OverlayLightButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.init(top: 4, leading: 8, bottom: 4, trailing: 8))
            .background(.bar, in: Capsule())
    }
}

public extension View {
    func overlayLightButtonStyle() -> some View {
        ModifiedContent(content: self, modifier: OverlayLightButtonStyle())
    }
}
