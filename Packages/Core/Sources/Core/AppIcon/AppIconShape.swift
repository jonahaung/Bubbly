//  AppIconShape.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

struct AppIconShape: Shape {
    var tailOffset: CGFloat = 0.35 // 0 → left, 1 → right

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        let radius = min(w, h) * 0.48 // rounder bubble
        let tailWidth = w * 0.16
        let tailHeight = h * 0.22

        let tailX = w * tailOffset

        var p = Path()

        // Main bubble (very round)
        p.addRoundedRect(
            in: CGRect(x: 0, y: 0, width: w, height: h - tailHeight),
            cornerSize: CGSize(width: radius, height: radius),
            style: .continuous
        )

        // Sharper tail (pointed)
        let baseY = h - tailHeight

        p.move(to: CGPoint(x: tailX, y: baseY))

        // left edge → tip
        p.addLine(to: CGPoint(x: tailX + tailWidth * 0.5, y: h))

        // tip → right edge
        p.addLine(to: CGPoint(x: tailX + tailWidth, y: baseY))

        p.closeSubpath()

        return p
    }
}
