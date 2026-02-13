import SwiftUI

public extension LayoutSubviews {
	func values<T: LayoutValueKey>(key: T.Type) -> [T.Value] {
		map { $0[key] }
	}
}
