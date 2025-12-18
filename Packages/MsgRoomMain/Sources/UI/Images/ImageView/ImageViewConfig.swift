//
//  ImageViewConfig.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 4/9/25.
//

import ImageLoader
import SwiftUI

public struct ImageViewConfig {

	public let size: ImageSize
    public let processors: [ImageProcessing]
    public let tapAction: ImageViewTapAction
	public let backgroundColor: Color?

    public init(
        size: ImageSize,
        processors: [ImageProcessing] = [],
        backgroundColor: Color? = nil,
        tapAction: ImageViewTapAction = .openPhotoViewer
    ) {
        self.size = size
        self.processors = processors
		self.backgroundColor = backgroundColor
		self.tapAction = tapAction
    }
}
