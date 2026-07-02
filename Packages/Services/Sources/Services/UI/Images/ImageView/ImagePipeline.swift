// © 2026 Aung Ko Min

import Foundation
import ImageLoader

public extension ImagePipeline {
    static let `default` = ImagePipeline {
        $0.dataLoader = {
            let config = URLSessionConfiguration.default
            config.urlCache = nil
            return DataLoader(configuration: config)
        }()
        $0.imageCache = ImageCache.shared
        $0.isLocalResourcesSupportEnabled = true
    }
}
