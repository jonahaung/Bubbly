//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation
import SwiftUI

public protocol CaseNameReflectable {
    var caseName: String { get }
}

public extension CaseNameReflectable {
    var caseName: String {
        let mirror = Mirror(reflecting: self)
        guard let caseName = mirror.children.first?.label else {
            return "\(self)"
        }
        return caseName
    }

    var localizedName: String {
        caseName.camelCaseToWords
    }
}

public extension String {
    var camelCaseToWords: String {
        guard !isEmpty else { return "" }
        let pattern = "([a-z])([A-Z])"
        let spaced = replacingOccurrences(of: pattern, with: "$1 $2", options: .regularExpression)
        return spaced.capitalized
    }
}

extension Visibility: CaseNameReflectable {}
