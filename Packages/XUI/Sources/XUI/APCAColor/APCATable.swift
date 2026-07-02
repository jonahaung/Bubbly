//  APCATable.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public extension Font {
    static func APCAContrastTarget(for size: CGFloat, weight: Font.Weight) -> Float {
        let columnWeights: [Font.Weight] = [
            .ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black
        ]

        let rowSizes: [CGFloat] = [
            12, 14, 15, 16, 18, 21, 24, 28, 32, 36, 42, 48, 60, 72, 96
        ]

        // TODO: Determine if this is body text and apply the other APCA table.
        let rows: [[Float]] = [
            [ 100, 100, 100, 100, 100, 100, 100, 100, 100 ],
            [ 100, 100, 100, 100, 100, 90, 75, 75, 75 ],
            [ 100, 100, 100, 100, 90, 75, 70, 70, 70 ],
            [ 100, 100, 100, 90, 75, 70, 60, 60, 60 ],
            [ 100, 100, 100, 75, 70, 60, 55, 55, 55 ],
            [ 100, 100, 90, 70, 60, 55, 50, 50, 50 ],
            [ 100, 100, 75, 60, 55, 50, 45, 45, 45 ],
            [ 100, 100, 70, 55, 50, 45, 43, 43, 43 ],
            [ 100, 90, 65, 50, 45, 43, 40, 40, 40 ],
            [ 100, 75, 60, 45, 43, 40, 38, 38, 38 ],
            [ 100, 70, 55, 43, 40, 38, 35, 35, 35 ],
            [ 90, 60, 50, 40, 38, 35, 33, 33, 33 ],
            [ 75, 55, 45, 38, 35, 33, 30, 30, 30 ],
            [ 60, 50, 40, 35, 33, 30, 30, 30, 30 ],
            [ 50, 45, 35, 33, 30, 30, 30, 30, 30 ]
        ]

        let rowIndex = rowSizes.lastIndex { $0 <= size } ?? 0
        let colIndex = columnWeights.lastIndex { $0.value <= weight.value } ?? 0

        // TODO: if size/weight land between table entries, bilinearly interpolate

        return rows[rowIndex][colIndex]
    }
}

#Preview("Contrast Table") {
    let sizes: [CGFloat] = [10, 12, 14, 15, 16, 18, 21, 24, 28, 32, 36, 42, 48, 60, 72, 96, 124]
    let weights: [Font.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]

    Grid {
        ForEach(sizes, id: \.self) { size in
            GridRow {
                Text(size, format: .number.precision(.fractionLength(...1)))

                ForEach(weights, id: \.self) { weight in
                    let contrast = Font.APCAContrastTarget(for: size, weight: weight)

                    Text(contrast, format: .number.precision(.fractionLength(0)))
                }
            }
        }
    }
}
