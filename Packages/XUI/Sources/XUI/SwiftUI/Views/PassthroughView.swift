//
//  PassthroughView.swift
//  XUI
//
//  Created by Aung Ko Min on 22/9/25.
//

import Combine
import Swift
import SwiftUI

// Shared cache (you can optimize with LRU or custom map)
public final class AnyViewCache {
	@MainActor public static let shared = AnyViewCache()
	private var cache = [AnyHashable: _opaque_View]()

	public func view(for key: AnyHashable) -> _opaque_View? {
		cache[key]
	}

	public func setView(_ view: _opaque_View, for key: AnyHashable) {
		cache[key] = view
	}

	@MainActor public func cachedView(for id: String) -> _opaque_View? {
		Self.shared.view(for: id)
	}
}

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
	func _opaque_environmentObject<B: ObservableObject>(_: B) -> _opaque_View
	func _opaque_environment<B: Observable & AnyObject>(_: B) -> _opaque_View
	func _opaque_environmentInject<B: Hashable>(_: B) -> _opaque_View
	func _opaque_getViewName() -> AnyHashable?

	func eraseToAnyView() -> AnyView
	func eraseToCachedAnyView(for id: String) -> _opaque_View
}

extension _opaque_View where Self: View {
	@MainActor @inlinable
	public func _opaque_environmentObject<B: ObservableObject>(_ bindable: B) -> _opaque_View {
		PassthroughView(content: environmentObject(bindable))
	}
	@MainActor @inlinable
	public func _opaque_environment<B: Observable & AnyObject>(_ bindable: B) -> _opaque_View {
		PassthroughView(content: environment(bindable))
	}
	@MainActor
	@inlinable
	public func _opaque_environmentInject<B: Hashable>(_ bindable: B) -> _opaque_View {
		PassthroughView { self.environment(\.anyObservable, bindable) }
	}
	@inlinable
	public func _opaque_getViewName() -> AnyHashable? {
		nil
	}
	@inlinable
	public func _opaque_identity() -> AnyHashable {
		if let name = _opaque_getViewName() {
			return name
		}
		return AnyHashable(ObjectIdentifier(Self.self))
	}
	@inlinable
	public func eraseToAnyView() -> AnyView {
		AnyView(self)
	}
	@inlinable
	@MainActor public func eraseToCachedAnyView(for id: String) -> _opaque_View {
		if let cached = AnyViewCache.shared.view(for: id) {
			return cached
		}
		let v = self
		AnyViewCache.shared.setView(v, for: id)
		return v
	}
}

extension ModifiedContent: @preconcurrency _opaque_View where Content: View, Modifier: ViewModifier {

}
public protocol _opaque_DiffableView: _opaque_View {
	func isVisuallyEqual(to other: _opaque_DiffableView) -> Bool
}

extension _opaque_DiffableView where Self: Equatable, Self: View {
	public func isVisuallyEqual(to other: _opaque_DiffableView) -> Bool {
		guard let otherView = other as? Self else { return false }
		return self == otherView
	}
}
public extension View {
	func opaqueView() -> _opaque_View {
		PassthroughView { self }
	}
}
public extension View {
	func opaqueCachedView(for id: String) -> _opaque_View {
		PassthroughView { self }.eraseToCachedAnyView(for: id)
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
