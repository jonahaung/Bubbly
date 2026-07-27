//  ToastStyle.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI
import Foundation

public enum ToastStyle: Sendable, Hashable, CaseIterable {
    case notification, alert

    var alignment: Alignment {
        switch self {
        case .notification:
            .top
        case .alert:
            .bottom
        }
    }

    var edge: Edge {
        switch self {
        case .notification:
            .top
        case .alert:
            .bottom
        }
    }
}
