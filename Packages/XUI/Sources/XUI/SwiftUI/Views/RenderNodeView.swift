//  RenderNodeView.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Swift
import Combine
import SwiftUI

@frozen
@_documentation(visibility: internal)
public struct RenderNodeView<Content: View>: RenderNode, View {
    public let content: Content

    @_optimize(speed)
    @inlinable
    public init(content: Content) {
        self.content = content
    }

    @_optimize(speed)
    @inlinable
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    @_optimize(speed)
    @inlinable
    public var body: some View {
        content
    }
}

@MainActor
public protocol RenderNode: Sendable {
    func injectEnvironmentObject(_: some ObservableObject) -> RenderNode
    func injectEnvironment(_: some Observable & AnyObject) -> RenderNode
    func injectPayload(_: some Hashable) -> RenderNode
    func renderID() -> AnyHashable

    func eraseToNode() -> AnyView
}

public extension RenderNode where Self: View {
    @inlinable
    func injectEnvironmentObject(_ bindable: some ObservableObject) -> RenderNode {
        RenderNodeView(content: environmentObject(bindable))
    }

    @inlinable
    func injectEnvironment(_ bindable: some Observable & AnyObject) -> RenderNode {
        RenderNodeView(content: environment(bindable))
    }

    @inlinable
    func injectPayload(_ bindable: some Hashable) -> RenderNode {
        RenderNodeView { self.environment(\.anyObservable, bindable) }
    }

    @inlinable
    func renderID() -> AnyHashable {
        AnyHashable(ObjectIdentifier(Self.self))
    }

    @inlinable
    func nodeIdentity() -> AnyHashable {
        renderID()
    }

    @inlinable
    func eraseToNode() -> AnyView {
        AnyView(self)
    }
}

public protocol OpaqueRenderableView: RenderNode {
    func renderKey() -> AnyHashable
}

public extension OpaqueRenderableView where Self: View {
    func renderKey() -> AnyHashable {
        AnyHashable(ObjectIdentifier(Self.self))
    }
}

public protocol OpaqueDiffableView: OpaqueRenderableView {
    func isVisuallyEqual(to other: OpaqueDiffableView) -> Bool
}
 
public extension OpaqueDiffableView {
    func isVisuallyEqual(to other: OpaqueDiffableView) -> Bool {
        renderKey() == other.renderKey()
    }
}

public extension View {
    @MainActor
    func opaqueView() -> RenderNode {
        RenderNodeView { self }
    }
}

public extension EnvironmentValues {
    @Entry var anyObservable: AnyHashable?
}
