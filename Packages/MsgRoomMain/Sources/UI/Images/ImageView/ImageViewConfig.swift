//
//  ImageViewConfig.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 4/9/25.
//

import ImageLoader
import SwiftUI

public struct ImageViewConfig {
    public typealias Size = any ImageSize
    public var size: Size?
    public var processors: [ImageProcessing]
    public var tapAction: ImageViewTapAction
    public var backgroundColor: Color?

    public init(
        size: Size? = nil,
        processors: [ImageProcessing] = [],
        backgroundColor: Color? = nil,
        tapAction: ImageViewTapAction = .openPhotoViewer
    ) {
        self.size = size
        self.processors = processors
        self.tapAction = tapAction
        self.backgroundColor = backgroundColor
    }
}
