//  WaterfallLayout.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

public struct WaterfallLayout: Layout {
    private let columnCount: Int
    private let spacing: CGFloat

    public init(columnCount: Int = 2, spacing: CGFloat = 2) {
        self.columnCount = columnCount
        self.spacing = spacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) -> CGSize {
        let result = Waterfall(
            columnCount: columnCount,
            origin: .zero,
            width: proposal.replacingUnspecifiedDimensions().width,
            spacing: spacing,
            subviews: subviews
        )
        return result.bounds.size
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) {
        let result = Waterfall(
            columnCount: columnCount,
            origin: bounds.origin,
            width: proposal.replacingUnspecifiedDimensions().width,
            spacing: spacing,
            subviews: subviews
        )
        result.columns
            .flatMap(\.self)
            .forEach { subview, frame in
                subview.place(
                    at: frame.origin,
                    proposal: .init(width: frame.width, height: frame.height)
                )
            }
    }

    struct Waterfall {
        typealias Column = [(LayoutSubview, CGRect)]
        let columns: [Column]

        let bounds: CGRect

        init(
            columnCount: Int,
            origin: CGPoint,
            width: CGFloat,
            spacing: CGFloat,
            subviews: Subviews
        ) {
            let gapCount = max(0, columnCount - 1)
            let columnWidth = (width - CGFloat(gapCount) * spacing) / CGFloat(columnCount)
            func column(index: Int) -> Column {
                let sizes: [(LayoutSubview, CGSize)] = stride(
                    from: index,
                    to: subviews.count,
                    by: columnCount
                ).compactMap { index in
                    guard subviews.indices.contains(index) else { return nil }
                    let subview = subviews[index]
                    return (subview, subview.sizeThatFits(.init(width: width, height: nil)))
                }
                return sizes.reduce(into: []) { partialResult, subviewSize in
                    let (subview, size) = subviewSize
                    let lastFrame = partialResult.last?.1 ?? CGRect(
                        x: origin.x + columnWidth * CGFloat(index) + spacing * CGFloat(index),
                        y: origin.y - spacing,
                        width: columnWidth,
                        height: .zero
                    )
                    let frame = CGRect(
                        x: lastFrame.minX,
                        y: lastFrame.maxY + spacing,
                        width: lastFrame.width,
                        height: size.height
                    )
                    partialResult.append((subview, frame))
                }
            }
            let columns = (0 ..< columnCount).map(column(index:))
            self.columns = columns
            bounds = columns.compactMap(\.last?.1).reduce(into: .zero) { $0 = $0.union($1) }
        }
    }
}
