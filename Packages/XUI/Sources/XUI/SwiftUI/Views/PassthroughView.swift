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
	func _opaque_environmentObject<B: ObservableObject>(_: B) -> _opaque_View
	func _opaque_getViewName() -> AnyHashable?

	func eraseToAnyView() -> AnyView
}

// MARK: - Implementation

extension _opaque_View where Self: View {
	@MainActor @inlinable
	public func _opaque_environmentObject<B: ObservableObject>(_ bindable: B) -> _opaque_View {
		PassthroughView(content: environmentObject(bindable))
	}

	@inlinable
	public func _opaque_getViewName() -> AnyHashable? {
		nil
	}

	@inlinable
	public func eraseToAnyView() -> AnyView {
		AnyView(self)
	}
}

extension ModifiedContent: @preconcurrency _opaque_View where Content: View, Modifier: ViewModifier {

}
