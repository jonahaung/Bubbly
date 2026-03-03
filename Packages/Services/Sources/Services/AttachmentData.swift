//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import XUI

public enum AttachmentData: Sendable, Hashable, Equatable {
    case image(thumbnail: UIImage)
    case imageUpload(localURL: URL, thumbnail: UIImage)
    case link(thumbnail: UIImage)
    case video(videoURL: URL, thumbnail: UIImage)
}
