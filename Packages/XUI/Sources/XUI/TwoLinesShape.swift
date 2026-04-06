//
//  TwoLinesShape.swift
//  XUI
//
//  Created by Aung Ko Min on 5/4/26.
//

import SwiftUI

public struct TwoLinesShape: Shape {
    public var lineThickness: CGFloat = 0.17
    public var gap: CGFloat = 0.25
    public var bottomLineScale: CGFloat = 0.7

    public func path(in rect: CGRect) -> Path {
        var path = Path()

        // Force square drawing area (SF Symbols style)
        let side = min(rect.width, rect.height)
        let square = CGRect(
            x: rect.midX - side / 2,
            y: rect.midY - side / 2,
            width: side,
            height: side
        )

        let lineHeight = square.height * lineThickness
        let centerY = square.midY

        let topY = centerY - gap * square.height
        let bottomY = centerY + gap * square.height

        let topRect = CGRect(
            x: square.minX,
            y: topY - lineHeight / 1.5,
            width: square.width,
            height: lineHeight
        )

        let bottomRect = CGRect(
            x: square.minX,
            y: bottomY - lineHeight / 1.5,
            width: square.width * bottomLineScale,
            height: lineHeight
        )

        path.addRoundedRect(
            in: topRect,
            cornerSize: CGSize(width: lineHeight / 1.5, height: lineHeight / 1.5)
        )

        path.addRoundedRect(
            in: bottomRect,
            cornerSize: CGSize(width: lineHeight / 1.5, height: lineHeight / 1.5)
        )

        return path
    }
}
