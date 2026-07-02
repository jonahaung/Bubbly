//
//  CGSize++.swift
//  XUI
//
//  Created by Aung Ko Min on 14/5/26.
//

import Foundation

public extension CGSize {
    var isPortrait: Bool {
        height > width
    }
    var isLandscape: Bool {
        width > height
    }
    var isSquare: Bool {
        width == height
    }
}
