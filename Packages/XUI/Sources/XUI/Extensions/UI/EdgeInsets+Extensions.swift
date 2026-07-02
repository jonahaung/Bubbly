//  EdgeInsets+Extensions.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

public extension EdgeInsets {
    var horizontal: CGFloat {
        get {
            leading + trailing
        } set {
            leading = newValue / 2
            trailing = newValue / 2
        }
    }

    var vertical: CGFloat {
        get {
            top + bottom
        } set {
            top = newValue / 2
            bottom = newValue / 2
        }
    }
}
