// © 2026 Aung Ko Min

import SwiftUI

// MARK: - Sticker

public struct Sticker: Sendable {
    public let sticker: UIImage
    public let colorScheme: PhotoColorScheme

    public init(sticker: UIImage, colorScheme: PhotoColorScheme) {
        self.sticker = sticker
        self.colorScheme = colorScheme
    }
}

// MARK: - PhotoColorScheme

public struct PhotoColorScheme: @unchecked Sendable {
    public let colors: [Color]

    public init(colors: [Color]) {
        self.colors = colors
    }
}
