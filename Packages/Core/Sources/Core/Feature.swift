// © 2026 Aung Ko Min

import SwiftUI

public protocol Feature {
    associatedtype Content: View
    func build() -> Content
}
