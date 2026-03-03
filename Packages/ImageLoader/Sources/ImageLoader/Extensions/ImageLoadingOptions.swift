//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

public struct ImageLoadingOptions {
    @MainActor public static var shared = ImageLoadingOptions()

    public var placeholder: UIImage?
    public var failureImage: UIImage?
    public var isPrepareForReuseEnabled = true
    public var isProgressiveRenderingEnabled = true
    public var pipeline: ImagePipeline?
    public var processors: [any ImageProcessing] = []
    public var contentModes: ContentModes?
    public var tintColors: TintColors?

    public struct ContentModes {
        public var success: UIView.ContentMode
        public var failure: UIView.ContentMode
        public var placeholder: UIView.ContentMode

        public init(
            success: UIView.ContentMode,
            failure: UIView.ContentMode,
            placeholder: UIView.ContentMode
        ) {
            self.success = success
            self.failure = failure
            self.placeholder = placeholder
        }
    }

    public struct TintColors {
        public var success: UIColor?
        public var failure: UIColor?
        public var placeholder: UIColor?

        public init(
            success: UIColor?,
            failure: UIColor?,
            placeholder: UIColor?
        ) {
            self.success = success
            self.failure = failure
            self.placeholder = placeholder
        }
    }

    func contentMode(for response: ResponseType) -> UIView.ContentMode? {
        switch response {
        case .success: contentModes?.success
        case .placeholder: contentModes?.placeholder
        case .failure: contentModes?.failure
        }
    }

    func tintColor(for response: ResponseType) -> UIColor? {
        switch response {
        case .success: tintColors?.success
        case .placeholder: tintColors?.placeholder
        case .failure: tintColors?.failure
        }
    }

    public init(
        placeholder: UIImage? = nil,
        failureImage: UIImage? = nil,
        contentModes: ContentModes? = nil,
        tintColors: TintColors? = nil
    ) {
        self.placeholder = placeholder
        self.failureImage = failureImage
        self.contentModes = contentModes
        self.tintColors = tintColors
    }

    public init() {}

    enum ResponseType {
        case success
        case failure
        case placeholder
    }
}
