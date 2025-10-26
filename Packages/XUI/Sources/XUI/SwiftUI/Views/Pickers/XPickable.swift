//
//  XPickable.swift
//
//
//  Created by Aung Ko Min on 12/8/23.
//

import SwiftUI

public protocol XPickable: Hashable, Identifiable, Sendable, EmptyRepresentable, CaseIterable {
    var title: String { get }
}

extension XPickable {
    var isEmpty: Bool { self == Self.empty }
	var color: Color { .accentColor }
}

public protocol EmptyRepresentable: Sendable {
    static var empty: Self { get }
}

extension String: @retroactive CaseIterable {}
extension String: XPickable {
    public static var allCases: [String] {
        [""]
    }
    public static var empty: String {
        ""
    }
    public var title: String {
        self.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
