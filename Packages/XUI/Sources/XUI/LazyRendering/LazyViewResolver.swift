//
//  LazyViewResolver.swift
//  XUI
//
//  Created by Aung Ko Min on 17/4/26.
//

import SwiftUI

@_spi(Internal)
public protocol LazyViewResolver {
    func resolve<Content: View>(_ content: () -> Content) -> Content
}

@_documentation(visibility: internal)
public struct AnyLazyViewResolver {
    public typealias Resolve = (() -> (any View)) -> any View

    private let _resolve: Resolve

    public init(resolve: @escaping Resolve) {
        _resolve = resolve
    }

    public func resolve<Content: View>(_ content: () -> Content) -> Content {
        // Try to preserve type. If resolver returns a different concrete type,
        // fall back to the original content to avoid a crash in release.
        let resolved = _resolve(content)
        if let typed = resolved as? Content {
            return typed
        } else {
            assertionFailure(
                "AnyLazyViewResolver returned a different view type than expected. Falling back to original content."
            )
            return content()
        }
    }
}

@_spi(Internal)
extension AnyLazyViewResolver: LazyViewResolver {}

private struct DefaultLazyViewResolver: LazyViewResolver {
    func resolve<Content: View>(_ content: () -> Content) -> Content {
        content()
    }
}

@_spi(Internal)
public extension EnvironmentValues {
    @Entry var lazyViewResolver: any LazyViewResolver = DefaultLazyViewResolver()
}
@MainActor
@frozen
@_documentation(visibility: internal)
public struct ZeroSizeView: View {
    public var body: some View {
        EmptyView()
    }

    public init() {}
}
