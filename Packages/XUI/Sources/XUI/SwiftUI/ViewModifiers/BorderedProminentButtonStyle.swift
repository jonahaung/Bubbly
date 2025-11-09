//
//  BorderedProminentButtonStyle.swift
//
//
//  Created by Aung Ko Min on 20/2/23.
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
            .flexible(.horizontal)
            .foregroundStyle(Color.white)
            .frame(height: 38.scaled)
            .flexible(.horizontal)
            .background(Color.accentColor.gradient, in: Capsule())
            .contentShape(Capsule())
    }
}

public extension ButtonStyle where Self == RoundedButtonStyle {
    static var roundedButtonStyle: RoundedButtonStyle {
        RoundedButtonStyle()
    }
}

public extension View {
    func _borderedProminentButtonStyle() -> some View {
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
        .flexible(.horizontal)
        .background(Color.secondary.gradient, in: Capsule())
    }
}

public extension View {
    func _borderedProminentLightButtonStyle() -> some View {
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
    func _overlayLightButtonStyle() -> some View {
        ModifiedContent(content: self, modifier: OverlayLightButtonStyle())
    }
}

private struct NavigationLinkStyle: ViewModifier {
    func body(content: Content) -> some View {
        HStack(spacing: 0) {
            content
                .fixedSize()
            Color.clear
            SystemImage(.chevronRight)
                .imageScale(.small)
                .foregroundStyle(.tertiary)
        }
        .foregroundColor(.primary)
    }
}

public extension View {
    func _navigationLinkStyle() -> some View {
        ModifiedContent(content: self, modifier: NavigationLinkStyle())
    }
}

private struct BorderStyle: ViewModifier {
    let shape: AnyShape
    let color: Color
    let lineWidth: CGFloat
    func body(content: Content) -> some View {
        ZStack {
            shape
                .stroke(color, lineWidth: lineWidth)
            content
        }
    }
}

public extension View {
    func _borderStyle(shape: AnyShape = .init(RoundedRectangle(cornerRadius: 8)), _ color: Color = .init(uiColor: .opaqueSeparator), _ lineWidth: CGFloat = 1) -> some View {
        ModifiedContent(content: self, modifier: BorderStyle(shape: shape, color: color, lineWidth: lineWidth))
    }
}
