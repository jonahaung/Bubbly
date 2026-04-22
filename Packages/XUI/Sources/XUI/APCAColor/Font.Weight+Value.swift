//  Font.Weight+Value.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public extension Font.Weight {
    private struct _Weight {
        var value: CGFloat
    }

    init(value: CGFloat) {
        self = unsafeBitCast(_Weight(value: value), to: Self.self)
    }

    var value: CGFloat {
        unsafeBitCast(self, to: _Weight.self).value
    }
}
