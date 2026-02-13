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
