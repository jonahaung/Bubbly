//
// Copyright © 2026 Aung Ko Min. All rights reserved.
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
