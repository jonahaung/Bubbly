// © 2026 Aung Ko Min

#if os(iOS)
//
    // Copyright © 2026 Aung Ko Min. All rights reserved.
//

    import AVFoundation
    import UIKit

    public enum VideoFactory {
        static func generateVideoThumbnail(
            from url: URL,
            at time: CMTime = CMTime(
                seconds: 5,
                preferredTimescale: 600,
            ),
        ) async throws -> UIImage {
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true

            let cgImage = try await generator.image(at: time).image
            return UIImage(cgImage: cgImage)
        }
    }

#endif
