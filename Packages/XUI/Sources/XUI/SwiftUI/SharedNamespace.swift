//
//  SharedNamespace.swift
//  XUI
//
//  Created by Aung Ko Min on 30/8/25.
//

import SwiftUI

@MainActor
@Observable
public final class SharedNamespace {
    public var value: Namespace.ID?
    init(_ namespace: Namespace.ID? = nil) {
        value = namespace
    }
}

struct SharedNamespaceEnvironmentKey: @preconcurrency EnvironmentKey {
    @MainActor
    static let defaultValue: SharedNamespace = .init()
}

public extension EnvironmentValues {
    var namespace: SharedNamespace {
        get { self[SharedNamespaceEnvironmentKey.self] }
        set { self[SharedNamespaceEnvironmentKey.self] = newValue }
    }
}

public extension View {
    func namespace(_ value: Namespace.ID) -> some View {
        environment(\.namespace, SharedNamespace(value))
    }
}
