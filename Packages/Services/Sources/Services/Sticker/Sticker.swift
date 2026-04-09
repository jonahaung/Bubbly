//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI

public struct Sticker: Sendable {
    public let sticker: UIImage
    public let colorScheme: PhotoColorScheme

    public init(sticker: UIImage, colorScheme: PhotoColorScheme) {
        self.sticker = sticker
        self.colorScheme = colorScheme
    }
}

public struct PhotoColorScheme: @unchecked Sendable {
    public let colors: [Color]

    public init(colors: [Color]) {
        self.colors = colors
    }
}
