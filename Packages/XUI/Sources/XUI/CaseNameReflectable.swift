//
//  CaseNameReflectable.swift
//  XUI
//
//  Created by Aung Ko Min on 6/11/25.
//

import Foundation

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
		self.caseName.camelCaseToWords
	}
}
public extension String {
	var camelCaseToWords: String {
		guard !isEmpty else { return "" }
		let pattern = "([a-z])([A-Z])"
		let spaced = self.replacingOccurrences(of: pattern, with: "$1 $2", options: .regularExpression)
		return spaced.capitalized
	}
}
