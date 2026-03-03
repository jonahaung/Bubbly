//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

#if !os(macOS)
import UIKit
#else
import AppKit
#endif

public extension ImageProcessors {
    /// Processed an image using a specified closure.
    struct Anonymous: ImageProcessing, CustomStringConvertible {
        public let identifier: String
        private let closure: @Sendable (PlatformImage) -> PlatformImage?

        public init(id: String, _ closure: @Sendable @escaping (PlatformImage) -> PlatformImage?) {
            identifier = id
            self.closure = closure
        }

        public func process(_ image: PlatformImage) -> PlatformImage? {
            closure(image)
        }

        public var description: String {
            "AnonymousProcessor(identifier: \(identifier)"
        }
    }
}
