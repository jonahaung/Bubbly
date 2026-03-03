//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct LazyLoadedView<Body: View>: View {
    @Environment(\.lazyViewResolver) private var lazyViewResolver

    public let destination: () -> Body

    @_optimize(none)
    @inline(never)
    public init(destination: @escaping () -> Body) {
        self.destination = destination
    }

    @_optimize(none)
    @inline(never)
    public var body: some View {
        lazyViewResolver.resolve {
            destination()
        }
    }
}

@_documentation(visibility: internal)
public struct LazyAppearViewProxy {
    @_documentation(visibility: internal)
    public enum Appearance: Equatable {
        case active
        case inactive
    }

    // Internal storage (renamed to satisfy lint)
    var storedAppearance: Appearance
    var storedAppearanceBinding: Binding<Appearance>

    public var appearance: Appearance {
        get {
            storedAppearanceBinding.wrappedValue
        } nonmutating set {
            storedAppearanceBinding.wrappedValue = newValue
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storedAppearance == rhs.storedAppearance
    }
}

@frozen
@_documentation(visibility: internal)
public struct DeferredView<Content: View>: View {
    @usableFromInline
    let content: () -> Content

    @usableFromInline
    @State var didAppear: Bool = false
    @usableFromInline
    @State var didAppear2: Bool = false

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        Group {
            if didAppear2 {
                content()
            } else if didAppear {
                ZeroSizeView().onAppear {
                    if !didAppear2 {
                        didAppear2 = true
                    }
                }
            } else {
                ZeroSizeView()
                    .onAppear {
                        if !didAppear {
                            didAppear = true
                        }
                    }
            }
        }
        .transaction { transaction in
            if !(didAppear && didAppear2) {
                transaction.disablesAnimations = true
            }
        }
    }
}

/// A view that appears lazily.
@_documentation(visibility: internal)
public struct LazyAppearView<Content: View>: View {
    @_documentation(visibility: internal)
    public enum Placeholder {
        case hiddenFrame // frame of content.hidden()
    }

    private let placeholder: Placeholder?
    private let destination: (LazyAppearViewProxy) -> Content?
    private var debounceInterval: DispatchTimeInterval?
    private var explicitAnimation: Animation?
    private var disableAnimations: Bool

    @State private var updateAppearanceAction: DispatchWorkItem?

    @State private var appearance: LazyAppearViewProxy.Appearance = .inactive

    public init(
        initial: LazyAppearViewProxy.Appearance = .inactive,
        debounceInterval: DispatchTimeInterval? = nil,
        animation: Animation = .default,
        placeholder: Placeholder? = nil,
        @ViewBuilder destination: @escaping (LazyAppearViewProxy) -> Content
    ) {
        _appearance = .init(initialValue: initial)
        self.placeholder = placeholder
        self.destination = { destination($0) }
        self.debounceInterval = debounceInterval
        explicitAnimation = animation
        disableAnimations = false
    }

    public init(
        initial: LazyAppearViewProxy.Appearance = .inactive,
        debounceInterval: DispatchTimeInterval? = nil,
        animation: Animation = .default,
        placeholder: Placeholder? = nil,
        @ViewBuilder destination: @escaping () -> Content
    ) {
        _appearance = .init(initialValue: initial)
        self.placeholder = placeholder
        self.destination = { proxy in
            if proxy.appearance == .active {
                destination()
            } else {
                nil
            }
        }
        self.debounceInterval = debounceInterval
        explicitAnimation = animation
        disableAnimations = false
    }

    public var body: some View {
        ZStack {
            placeholderView
                .onAppear {
                    setAppearance(.active)
                }
                .onDisappear {
                    setAppearance(.inactive)
                }

            if let view = destination(
                LazyAppearViewProxy(
                    storedAppearance: appearance,
                    storedAppearanceBinding: Binding<LazyAppearViewProxy.Appearance>(
                        get: { appearance },
                        set: { setAppearance($0) }
                    )
                )
            ) {
                view
            }
        }
    }

    private var placeholderView: some View {
        ZStack {
            if let placeholder {
                if appearance == .inactive {
                    switch placeholder {
                    case .hiddenFrame:
                        destination(.init(
                            storedAppearance: .active,
                            storedAppearanceBinding: .constant(.active)
                        ))
                        .hidden()
                    }
                }
            } else {
                ZeroSizeView()
            }
        }
        .allowsHitTesting(false)
        .accessibility(hidden: false)
    }

    private func setAppearance(_ appearance: LazyAppearViewProxy.Appearance) {
        let mutateAppearance: () -> Void = {
            if let animation = explicitAnimation, !disableAnimations {
                withAnimation(animation) {
                    self.appearance = appearance
                }
            } else {
                withTransaction(.withoutAnimation) {
                    self.appearance = appearance
                }
            }
        }

        if let debounceInterval {
            let updateAppearanceAction = DispatchWorkItem(block: mutateAppearance)

            self.updateAppearanceAction?.cancel()
            self.updateAppearanceAction = updateAppearanceAction

            DispatchQueue.main.asyncAfter(
                deadline: .now() + debounceInterval,
                execute: updateAppearanceAction
            )
        } else {
            mutateAppearance()
        }
    }
}

public extension LazyAppearView {
    func delay(_ delay: DispatchTimeInterval?) -> Self {
        then {
            $0.debounceInterval = delay
        }
    }

    func animation(_ animation: Animation?) -> Self {
        then {
            $0.explicitAnimation = animation
            $0.disableAnimations = animation == nil
        }
    }

    func animationDisabled(_ disabled: Bool) -> Self {
        then {
            $0.disableAnimations = disabled

            if disabled {
                $0.explicitAnimation = nil
            }
        }
    }
}

private struct DestroyOnDisappear: ViewModifier {
    @State private var id = UUID()

    func body(content: Content) -> some View {
        content
            .id(id)
            .onDisappear {
                id = UUID()
            }
    }
}

public extension View {
    /// Resets the view's identity every time it disappears.
    func destroyOnDisappear() -> some View {
        modifier(DestroyOnDisappear())
    }
}

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
extension EnvironmentValues {
    struct LazyViewResolverKey: EnvironmentKey {
        typealias Value = any LazyViewResolver

        nonisolated(unsafe) static let defaultValue: Value = DefaultLazyViewResolver()
    }

    public var lazyViewResolver: any LazyViewResolver {
        get {
            self[LazyViewResolverKey.self]
        } set {
            self[LazyViewResolverKey.self] = newValue
        }
    }
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
