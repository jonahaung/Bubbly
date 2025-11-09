//
//  PassthroughView.swift
//  XUI
//
//  Created by Aung Ko Min on 22/9/25.
//

import Combine
import Swift
import SwiftUI

@frozen
@_documentation(visibility: internal)
public struct PassthroughView<Content: View>: @preconcurrency _opaque_View, View {
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

public protocol _opaque_View {
    func _opaque_environmentObject(_: some ObservableObject) -> _opaque_View
    func _opaque_environment(_: some Observable & AnyObject) -> _opaque_View
    func _opaque_environmentInject(_: some Hashable) -> _opaque_View
    func _opaque_getViewName() -> AnyHashable?

    func eraseToAnyView() -> AnyView
}

public extension _opaque_View where Self: View {
    @MainActor @inlinable
    func _opaque_environmentObject(_ bindable: some ObservableObject) -> _opaque_View {
        PassthroughView(content: environmentObject(bindable))
    }

    @MainActor @inlinable
    func _opaque_environment(_ bindable: some Observable & AnyObject) -> _opaque_View {
        PassthroughView(content: environment(bindable))
    }

    @MainActor
    @inlinable
    func _opaque_environmentInject(_ bindable: some Hashable) -> _opaque_View {
        PassthroughView { self.environment(\.anyObservable, bindable) }
    }

    @inlinable
    func _opaque_getViewName() -> AnyHashable? {
        nil
    }

    @inlinable
    func _opaque_identity() -> AnyHashable {
        if let name = _opaque_getViewName() {
            return name
        }
        return AnyHashable(ObjectIdentifier(Self.self))
    }

    @inlinable
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

extension ModifiedContent: @preconcurrency _opaque_View where Content: View, Modifier: ViewModifier {}

public protocol _opaque_DiffableView: _opaque_View {
    func isVisuallyEqual(to other: _opaque_DiffableView) -> Bool
}

public extension _opaque_DiffableView where Self: Equatable, Self: View {
    func isVisuallyEqual(to other: _opaque_DiffableView) -> Bool {
        guard let otherView = other as? Self else { return false }
        return self == otherView
    }
}

public extension View {
    func opaqueView() -> _opaque_View {
        PassthroughView { self }
    }
}

// MARK: - Custom Environment Key for `_opaque_environment`

private struct AnyObservableEnvironmentKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: AnyHashable? = nil
}

public extension EnvironmentValues {
    var anyObservable: AnyHashable? {
        get { self[AnyObservableEnvironmentKey.self] }
        set { self[AnyObservableEnvironmentKey.self] = newValue }
    }
}
