//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

//
//  ImageLoader.swift
//
//
//  Created by Aung Ko Min on 29/6/24.
//
import Foundation

/// A namespace with all available encoders.
public enum ImageEncoders {}

public extension ImageEncoding where Self == ImageEncoders.Default {
    static func `default`(compressionQuality: Float = 0.8) -> ImageEncoders.Default {
        ImageEncoders.Default(compressionQuality: compressionQuality)
    }
}

public extension ImageEncoding where Self == ImageEncoders.ImageIO {
    static func imageIO(type: AssetType, compressionRatio: Float = 0.8) -> ImageEncoders.ImageIO {
        ImageEncoders.ImageIO(type: type, compressionRatio: compressionRatio)
    }
}
