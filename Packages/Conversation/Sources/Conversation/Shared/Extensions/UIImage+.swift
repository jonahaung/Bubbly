#if os(iOS)
//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIImage {

    func downscaled(to maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }

        let scale = maxDimension / maxSide
        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)

        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

#endif
