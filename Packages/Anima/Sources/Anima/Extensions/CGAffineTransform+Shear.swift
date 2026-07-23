//  CGAffineTransform+Shear.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import CoreGraphics

extension CGAffineTransform {
    init(shearX x: CGFloat, y: CGFloat) {
        self = .identity
        c = x
        b = y
    }
}

func CGAffineTransformShear(_ t: CGAffineTransform, _ x: CGFloat, _ y: CGFloat) -> CGAffineTransform {
    t.concatenating(CGAffineTransform(shearX: x, y: y))
}
