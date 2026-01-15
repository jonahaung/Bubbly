//
//  UIImage+.swift
//
//
//  Created by Aung Ko Min on 18/7/23.
//

import SwiftUI

public extension UIImage {
	@inlinable
	@concurrent
	func resizedImage(maxSize: CGFloat) async -> UIImage? {
        let maxSizePixels = maxSize * self.scale
        let originalWidth = size.width
        let originalHeight = size.height
        let aspectRatio = originalWidth / originalHeight

        // Check if resizing is actually needed
        if originalWidth <= maxSizePixels, originalHeight <= maxSizePixels {
            return self
        }

        // Initialize variables
        var targetWidth: CGFloat
        var targetHeight: CGFloat

        // Calculate the scaling factor and new dimensions
        if originalWidth > originalHeight, originalWidth > maxSizePixels {
            targetWidth = maxSizePixels
            targetHeight = targetWidth / aspectRatio
        } else if originalHeight > originalWidth, originalHeight > maxSizePixels {
            targetHeight = maxSizePixels
            targetWidth = targetHeight * aspectRatio
        } else {
            targetWidth = originalWidth
            targetHeight = originalHeight
        }

        // Create a new image with the renderer
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: targetWidth, height: targetHeight),
            format: UIGraphicsImageRendererFormat.default()
        )

        let newImage = renderer.image { _ in
            self.draw(in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
        }

        return newImage
    }
}

public extension UIImage {
	var aspectRatio: CGFloat {
		return size.height.isZero ? 0 : size.width / size.height
	}
}
