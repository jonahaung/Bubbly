//  ToastStyle.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI
import Foundation

public enum ToastStyle: Sendable, Hashable, CaseIterable {
    case `default`, top, bottom

    var alignment: Alignment {
        switch self {
        case .default:
            .top
        case .top:
            .top
        case .bottom:
            .bottom
        }
    }

    var edge: Edge {
        if alignment == .top {
            return .top
        }
        return .bottom
    }
}
