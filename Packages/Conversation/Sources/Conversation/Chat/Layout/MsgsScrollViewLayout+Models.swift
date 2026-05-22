//  MsgsScrollViewLayout+Models.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Foundation
import SwiftUI
import Database
import Services

extension MsgsScrollViewLayout {
    struct Cache: Sendable, Equatable {
        var totalHeight: CGFloat
        var signatureHash: Int
    }
}
