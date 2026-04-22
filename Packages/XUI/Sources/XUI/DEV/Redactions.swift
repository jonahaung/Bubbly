//  Redactions.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public extension RedactionReasons {
    static let animatedPlaceholder: RedactionReasons = .init(rawValue: 100)
    static let hidden: RedactionReasons = .init(rawValue: 101)
}

public enum ShapeType {
    case rectangle
    case roundedRectangle(cornerRadius: CGFloat)
    case circle
}

public extension View {
    func redactable(shapeType: ShapeType = .roundedRectangle(cornerRadius: 12)) -> some View
    {
        modifier(Redactable(shapeType: shapeType))
    }
}

private struct AnimatedPlaceholder: ViewModifier {
    let shapeType: ShapeType
    @State private var size: CGSize = .zero

    @State private var xOffset: CGFloat = .zero
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    let gradient: Gradient = .init(colors: [Color.appSecondary, .appTertiary, .appSecondary])

    func body(content: Content) -> some View {
        content
            .opacity(.zero)
            .overlay(overlayView)
            .onReceive(timer) { _ in
                if xOffset == size.width {
                    xOffset = -size.width
                } else {
                    withAnimation(.linear(duration: 1)) {
                        xOffset = size.width
                    }
                }
            }
            .overlay(
                ZStack {
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                size = geometry.size
                            }
                    }
                }
            )
    }

    @ViewBuilder
    var overlayView: some View {
        switch shapeType {
        case .rectangle:
            addAnimationContainer { Rectangle() }
        case let .roundedRectangle(cornerRadius):
            addAnimationContainer { RoundedRectangle(cornerRadius: cornerRadius) }
        case .circle:
            addAnimationContainer { Circle() }
        }
    }

    func addAnimationContainer(content: () -> some Shape) -> some View {
        ZStack {
            content()
                .fill(Color.appSecondary)

            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: gradient,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: xOffset)
        }
        .clipShape(content())
    }
}

private struct Redactable: ViewModifier {
    @Environment(\.redactionReasons) private var reasons

    let shapeType: ShapeType

    func body(content: Content) -> some View {
        switch reasons {
        case .animatedPlaceholder:
            content
                .modifier(AnimatedPlaceholder(shapeType: shapeType))
        case .hidden:
            content
                .hidden()
        default:
            content
        }
    }
}
