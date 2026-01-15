//
//  AttachmentData.swift
//  Services
//
//  Created by Aung Ko Min on 20/10/25.
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
