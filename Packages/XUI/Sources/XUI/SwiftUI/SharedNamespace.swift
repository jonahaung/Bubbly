//
//  SharedNamespace.swift
//  XUI
//
//  Created by Aung Ko Min on 30/8/25.
//

import SwiftUI

@Observable
public final class SharedNamespace {
	public var value: Namespace.ID
	public init(_ namespace: Namespace.ID) {
		value = namespace
	}
}

public extension EnvironmentValues {
	@Entry var sharedNamespace: SharedNamespace?
}
